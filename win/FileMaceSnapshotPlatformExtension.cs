/* Optional preprocessor symbols:
 * LP64 - Define if compiling for a target where pointer types use 64 bits
 * NO_USING - Define to ignore 'using' directives;
     useful for using this source file in PowerShell.
 */

// Reference: https://github.com/rapid7/meterpreter/blob/master/source/extensions/priv/server/timestomp.c

// All this work because I just wanted to access the E (Entry Modified) in MACE
// (in C#
//   (for use in PowerShell
//     (because no one trusts my precompiled executables ( :'-) ))))
//well but hey this makes for good future reference on P/Invoke

#if !NO_USING // Suppress 'using' directive for use in PowerShell
using Microsoft.Win32.SafeHandles;
#endif

// IntPtr.Size isn't a constant
// and primitive type {nint} (native int) isn't supported in PowerShell v5.1 (Windows 10; .NET 4.5)
// so I'll have the consumer define whether or not we're 64-bit.
const int INTPTR_WIDTH =
#if LP64
	8;
#else
	4;
#endif

#region Ported constants, typedefs, macros
[Flags]
public enum ACCESS_MASK : uint
{
	FILE_READ_ATTRIBUTES = 0x0080,
	FILE_WRITE_ATTRIBUTES = 0x0100
}

[Flags]
public enum FILE_FLAG : uint
{
	BACKUP_SEMANTICS = 0x02000000
}

public enum FILE_INFORMATION_CLASS
{
	FileBasicInformation = 4
}

public enum NTSTATUS
{
	STATUS_SUCCESS = 0x00000000
}

public struct FILE_BASIC_INFORMATION
{
	public LARGE_INTEGER CreationTime;
	public LARGE_INTEGER LastAccessTime;
	public LARGE_INTEGER LastWriteTime;
	public LARGE_INTEGER ChangeTime;
	public uint FileAttributes; 
}

public struct FileBasicInformation
{ // An easier-to-use object container for .NET
	public string FullName;
	public DateTime CreationTime;
	public DateTime LastAccessTime;
	public DateTime LastWriteTime;
	public DateTime ChangeTime;
	public uint FileAttributes;

	public static DateTime NtFileBasicInformationTimeToDateTime(LARGE_INTEGER t)
	{
		// In FILE_BASIC_INFORMATION (wdm.h):
		//    time values are number of 100ns intervals
		//    since start of Y1601 in the Gregorian calendar
		// In DateTime (.NET):
		//    time values are number of 100ns intervals
		//    since start of Y0001 in the Gregorian calendar

		// difference in intervals between the above two epochs;
		// calculated via PowerShell command: `[datetime]'1601-01-01' - [datetime]'0001-01-01'`
		// (50,491,123,200,000,000,0)
		const long DT = 504911232000000000;
		return new DateTime(t.QuadPart + DT);
	}

	public static implicit operator FileBasicInformation(FILE_BASIC_INFORMATION fbi)
	{
		return new FileBasicInformation()
		{
			FullName = String.Empty,
			CreationTime = NtFileBasicInformationTimeToDateTime(fbi.CreationTime),
			LastAccessTime = NtFileBasicInformationTimeToDateTime(fbi.LastAccessTime),
			LastWriteTime = NtFileBasicInformationTimeToDateTime(fbi.LastWriteTime),
			ChangeTime = NtFileBasicInformationTimeToDateTime(fbi.ChangeTime),
			FileAttributes = fbi.FileAttributes
		};
	}
}

[StructLayout(LayoutKind.Explicit)]
public struct IO_STATUS_BLOCK
{
	[FieldOffset(0)]
	public uint Status;
	[FieldOffset(0)]
	public IntPtr Pointer;
	[FieldOffset(INTPTR_WIDTH)]
	public UIntPtr Information;
}

[StructLayout(LayoutKind.Explicit)]
public struct LARGE_INTEGER
{
	public struct LI_PART
	{
		public uint LowPart;
		public int HighPart;
	}

	[FieldOffset(0)]
	LI_PART DUMMYSTRUCTNAME;
	[FieldOffset(0)]
	public LI_PART u;
	[FieldOffset(0)]
	public long QuadPart;
}

static uint HRESULT_FROM_NT(uint NtStatus)
{ return NtStatus | 0x10000000 /*FACILITY_NT_BIT*/; }

static bool NT_SUCCESS(uint NtStatus)
{
	// Success type if [0, 0x40000000)
	// Informational type if [0x40000000, 0x80000000)
	return 0 <= NtStatus && NtStatus < 0x80000000;
}
#endregion

[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
public static extern SafeFileHandle CreateFileW(
	string lpFileName,
	uint dwDesiredAccess,
	System.IO.FileShare dwShareMode,
	IntPtr lpSecurityAttributes,
	System.IO.FileMode dwCreationDisposition,
	uint dwFlagsAndAttributes,
	IntPtr hTemplateFile
);

// SetLastError set according to pinvoke.net
[DllImport("ntdll.dll", SetLastError=true)]
public static extern uint NtQueryInformationFile(
	SafeFileHandle FileHandle,
	out IO_STATUS_BLOCK IoStatusBlock,
	IntPtr pFileInformation,
	uint Length,
	FILE_INFORMATION_CLASS FileInformationClass
);

public static FileBasicInformation QueryInformationFileBasic(string path)
{
	uint retval;

	FILE_BASIC_INFORMATION finfo;
	using (SafeFileHandle hfil = CreateFileW(
		path,
		(uint)ACCESS_MASK.FILE_READ_ATTRIBUTES, //DesiredAccess
		System.IO.FileShare.None,
			// any other access (including read-only) may tamper with timestamps
		IntPtr.Zero, //SecurityAttributes - n/a
		System.IO.FileMode.Open, //CreationDisposition - file must already exist
		(uint)FILE_FLAG.BACKUP_SEMANTICS, //FlagsAndAttributes
			// ignored for existing files
			// 'FILE_FLAG_BACKUP_SEMANTICS' needed to obtain directory handles
		IntPtr.Zero //TemplateFile - n/a - ignored for existing files
	)) {
		if (hfil.IsInvalid)
			Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());

		IO_STATUS_BLOCK iosb;
		uint cbfinfo = (uint)Marshal.SizeOf(typeof(FILE_BASIC_INFORMATION));
		IntPtr pfinfo = Marshal.AllocHGlobal((int)cbfinfo);
		try
		{
			retval = NtQueryInformationFile(hfil, out iosb, pfinfo, cbfinfo, FILE_INFORMATION_CLASS.FileBasicInformation);
			if (!NT_SUCCESS(retval))
				Marshal.ThrowExceptionForHR(unchecked((int)HRESULT_FROM_NT(retval)));
			finfo = (FILE_BASIC_INFORMATION)Marshal.PtrToStructure(pfinfo, typeof(FILE_BASIC_INFORMATION));
		}
		finally
		{
			Marshal.FreeHGlobal(pfinfo);
		}
	}

	FileBasicInformation fbi = finfo;
	fbi.FullName = path;
	return fbi; //open up
}
