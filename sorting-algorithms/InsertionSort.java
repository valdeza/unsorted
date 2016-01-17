/**
 * The first in a series of probably overly-complicated implementations of common sorting algorithms
 * (but written without peeking at the answer, if that counts for anything).
 */

import java.lang.Comparable;

public class InsertionSort 
{
	/**
	 * Sorts a given collection of elements from least to greatest.
	 * @param T1 Type of elements in array<br />Must implement java.lang.Comparable.
	 * @param c Collection to sort
	 */
	public static <T1 extends Comparable<T1>> void sort(T1[] a) 
	{
		// Last element (first to check) skipped; serves as initial comparison.
		for ( int probe = a.length - 2; probe >= 0; probe-- )
		{
			if (a[probe].compareTo(a[probe+1]) <= 0)
				continue;
			//else
			// Prepare to reposition element.
			boolean reachedEnd = true; // Assume true unless following for loop exits early.
			T1 temp = a[probe];
			// Sentinel condition ends one element early to avoid ArrayIndexOutOfBoundsException. 
			for ( int probeRepos = probe + 1; probeRepos < a.length - 1; probeRepos++ )
			{
				// Shift current second probe to examine the next.
				a[probeRepos-1] = a[probeRepos];
				if (temp.compareTo(a[probeRepos+1]) <= 0)
				{ // Proper sorted place found.
					a[probeRepos] = temp;
					reachedEnd = false;
					break;
				}
			}
			if (reachedEnd)
			{ // Place $temp at the end.
				int lastIdx = a.length - 1;
				a[lastIdx-1] = a[lastIdx];
				a[lastIdx] = temp;
			}
		}
	}
}
