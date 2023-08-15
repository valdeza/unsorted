"""
Graphs directory disk usage over time using file timestamps

SETUP:
prerequisites: python-3.10
. Run command `python3 -m venv graph_dir_du.venv` to initialise a Python virtual environment
  (only needs to be run once)
. Run the appropriate activation script for your terminal.
  In Windows, run either graph_dir_du.venv\Scripts\activate.bat or graph_dir_du.venv\Scripts\Activate.ps1
  In Linux, run `source graph_dir_du.venv/bin/activate
  If done properly, the command prompt should now be prefixed with '(graph_dir_du.venv)'.
. Run command `pip3 install graph_dir_du_requirements.txt

USAGE:
. Run `python graph_dir_du.py --help` to see available options.`
"""

from __future__ import annotations

import logging
import math
import os
import os.path
from datetime import datetime
from math import floor, log10
from typing import TYPE_CHECKING, AnyStr, Generator, NamedTuple

import matplotlib.dates
import matplotlib.pyplot as plt
import matplotlib.ticker

if TYPE_CHECKING:
    from _typeshed import GenericPath

class Fstat(NamedTuple):
    """os.stat() attributes of interest"""
    size: int
    ctime: float
    mtime: float

class MPLByteFormatter(matplotlib.ticker.Formatter):
    PREFIX_THRESHOLDS = (
        ('' , 10**3,  1<<10),
        ('K', 10**6,  1<<20),
        ('M', 10**9,  1<<30),
        ('G', 10**12, 1<<40),
        ('T', 10**15, 1<<50),
        ('P', 10**18, 1<<60),
    )

    def __init__(self, si=False):
        self.si = si

    def __call__(self, x, pos=0):
        # prevent math domain error from calculating log(0)
        if x == 0:
            return '0 B'
        for pt in MPLByteFormatter.PREFIX_THRESHOLDS:
            cutoff = pt[1] if self.si else pt[2]
            if x < cutoff:
                cutoff = int(cutoff / (10**3 if self.si else 1<<10))
                size_concise = x / cutoff
                if not self.si:
                    # clean up number from unclean math division
                    if size_concise >= 1000:
                        size_concise = int(size_concise)
                    else:
                        # round to 4 significant digits
                        #FIXME size_concise = round(size_concise, int(3 - floor(log10(abs(x)))))

                        # temporary: set decimal places
                        size_concise = round(size_concise, 4)
                        pass
                return f"{size_concise} {pt[0]}{'i' if (pt[0] and not self.si) else ''}B"
        #fallback: use largest threshold (who would be using this script on petabytes of data)
        pt = MPLByteFormatter.PREFIX_THRESHOLDS[-1]
        cutoff = (pt[1] / 1<<10) if self.si else (pt[2] / 10**3)
        return f"{x/cutoff:.3f} {pt[0]}{'i' if self.si else ''}B"

def get_fstats(*dirs: GenericPath[AnyStr], recurse: bool) -> Generator[tuple[AnyStr, os.stat_result], None, None]:
    """Returns tuple (filename, os.stat()) for all files (no directories) in all `dirs`.
    :param dirs: directory(ies) to analyse
    :param recurse: include directories recursively
    """
    for d in dirs:
        if recurse:
            for root, _unused_dirs, files in os.walk(d):
                for fname in files:
                    fullpath = os.path.join(root, fname)
                    if os.path.isfile(fullpath):
                        yield fullpath, os.stat(fullpath, follow_symlinks=False)
        else:
            with os.scandir(d) as idir:
                for e in idir:
                    if e.is_file(follow_symlinks=False):
                        yield e.path, e.stat(follow_symlinks=False)

def run(args):
    file_count = 0
    total_disk_use_bytes = 0
    file_size_dates: list[Fstat] = []
    for path, statres in get_fstats(*args.directory, recurse=args.recursive):
        total_disk_use_bytes += statres.st_size
        file_count += 1
        fstat = Fstat(
            statres.st_size,
            statres.st_ctime if (os.name == 'nt') else statres.st_mtime,
            statres.st_mtime)
        if fstat.ctime > fstat.mtime:
            logging.warning('encountered ctime later than mtime; using ctime:\n  file: %s\n  ctime: %s\n  mtime: %s',
                path,
                datetime.fromtimestamp(fstat.ctime),
                datetime.fromtimestamp(fstat.mtime))
            fstat = fstat._replace(mtime=fstat.ctime)
        file_size_dates.append(fstat)
    file_size_dates.sort(key=lambda fsd: fsd.ctime)



    # Generate plot data
    if len(file_size_dates) == 0:
        logging.error('no work to do: 0 files counted')
    fsd = file_size_dates[0]
    # (similar-to (Ctrl+F): 8b0c93d0-42a0-4982-a0ac-c85a4f4e7b8c ; consider updating other areas on change)
    # if ctime is unknown (unix platform?), register an instant jump in cumulative size
    if fsd.ctime == fsd.mtime:
        ongoing_intervals = []
        # using math.nextafter() to keep matplotlib graph continuous
        x_t = [fsd.ctime, math.nextafter(fsd.ctime, math.inf)]
        y_cumulative_size = [0, fsd.size]
    else:
        ongoing_intervals = [fsd]
        x_t = [fsd.ctime]
        y_cumulative_size = [0]
    #end-similar-to
    for fsd in file_size_dates[1:]:
        while ongoing_intervals:
            # process all ongoing intervals before this next new interval
            fsd_ongoing_min_mtime = min(ongoing_intervals, key=lambda fsd_: fsd_.mtime)
            if fsd_ongoing_min_mtime.mtime > fsd.ctime:
                break
            #else: an interval ended before the next new interval
            # calculate size development since last recorded timestamp
            bytes_delta = 0
            for i in ongoing_intervals:
                bytes_delta += i.size / (i.mtime - i.ctime) * (fsd_ongoing_min_mtime.mtime - x_t[-1])
            x_t.append(fsd_ongoing_min_mtime.mtime)
            y_cumulative_size.append(y_cumulative_size[-1] + int(bytes_delta+0.5))
            ongoing_intervals.remove(fsd_ongoing_min_mtime)

        # process new interval
        x_t.append(fsd.ctime)
        bytes_delta = 0
        for i in ongoing_intervals:
            bytes_delta += i.size / (i.mtime - i.ctime) * (x_t[-1] - x_t[-2])
        y_cumulative_size.append(y_cumulative_size[-1] + int(bytes_delta+0.5))
        # (similar-to (Ctrl+F): 8b0c93d0-42a0-4982-a0ac-c85a4f4e7b8c ; consider updating other areas on change)
        # if ctime is unknown (unix platform?), register an instant jump in cumulative size
        if fsd.ctime == fsd.mtime:
            x_t.append(math.nextafter(x_t[-1], math.inf))
            bytes_delta = 0
            for i in ongoing_intervals:
                bytes_delta += i.size / (i.mtime - i.ctime) * (x_t[-1] - x_t[-2])
            y_cumulative_size.append(y_cumulative_size[-1] + int(bytes_delta+0.5) + fsd.size)
        else:
            ongoing_intervals.append(fsd)
        #end-similar-to
    #end-foreach file_size_dates[-1:]
    # all files are accounted for, now run a burn down on all ongoing intervals
    ongoing_intervals.sort(key=lambda fsd: fsd.mtime, reverse=True)
    while ongoing_intervals:
        # calculate size development since last recorded timestamp
        bytes_delta = 0
        for i in ongoing_intervals:
            bytes_delta += i.size / (i.mtime - i.ctime) * (ongoing_intervals[-1].mtime - x_t[-1])
        x_t.append(ongoing_intervals[-1].mtime)
        y_cumulative_size.append(y_cumulative_size[-1] + int(bytes_delta+0.5))
        ongoing_intervals.pop()

    print(file_count, 'files totalling', total_disk_use_bytes, 'B')



    # Graph data
    WINDOW_TITLE = 'Disk Usage Over Time'
    fig, ax = plt.subplots()
    ax.plot([datetime.fromtimestamp(ts) for ts in x_t], y_cumulative_size)
    ax.set_xlabel('datetime')
    ax.set_ylabel('cumulative file size')
    ax.set_title(WINDOW_TITLE)
    cdf = matplotlib.dates.ConciseDateFormatter(ax.xaxis.get_major_locator())
    ax.xaxis.set_major_formatter(cdf)
    ax.yaxis.set_major_formatter(MPLByteFormatter(si=args.si))
    mgr = plt.get_current_fig_manager()
    mgr.set_window_title(WINDOW_TITLE)
    plt.show(block=True)

def main():
    import argparse
    parser = argparse.ArgumentParser(description='graphs directory disk usage over time using file timestamps')
    parser.add_argument('directory',
        help='directory(ies) to analyse',
        nargs='*',
        default=['.'])
    parser.add_argument('-R', '--recursive',
        help='include subdirectories recursively',
        action='store_true')
    parser.add_argument('--si',
        help='in printing file sizes, use powers of 1000 not 1024',
        action='store_true')
    logging.basicConfig()
    run(parser.parse_args())

if __name__ == '__main__':
    main()
