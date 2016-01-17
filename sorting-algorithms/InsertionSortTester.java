import java.util.Random;

public class InsertionSortTester 
{
	private static Random rand = new Random();
	static long _timestamp = System.currentTimeMillis();
	
	//TODO Aren't single system time measures unreliable? Each test should probably be done a couple hundred times or something.
	public static void main(String[] args) 
	{
		Integer[] a = new Integer[] {1};
		performSimpleBenchmark(a);
		System.out.println();
		
		a = new Integer[] {1, 2};
		performSimpleBenchmark(a);
		System.out.println();
		
		a = new Integer[] {2, 1};
		performSimpleBenchmark(a);
		System.out.println();
		
		a = new Integer[] {2, 2, 2};
		performSimpleBenchmark(a);
		System.out.println();
		
		a = new Integer[] {3, 1, 3, 5, 3};
		performSimpleBenchmark(a);
		System.out.println();
		
		for ( int i = 0 ; i < 3 ; i++ )
		{
			a = generateRandomIntArray(5);
			performSimpleBenchmark(a);
			System.out.println();
		}
	}
	
	/**
	 * Returns an array of specified {@code size} containing random ints from 1 to 100.
	 */
	private static Integer[] generateRandomIntArray(int size)
	{
		Integer[] a = new Integer[size];
		for ( int i = 0 ; i < a.length ; i++ )
			a[i] = rand.nextInt(100);
		
		return a;
	}
	
	private static void performSimpleBenchmark(Integer[] a)
	{
		printIntArray(a);
		System.out.println(System.currentTimeMillis());
		InsertionSort.<Integer>sort(a);
		System.out.printf("Time taken: %dms\n", System.currentTimeMillis() - _timestamp);
		System.out.println(System.currentTimeMillis());
		printIntArray(a);
	}
	
	private static void printIntArray(Integer[] a)
	{
		for ( Integer e : a )
		{
			System.out.print(e.toString());
			System.out.print(" ");
		}
		System.out.println();
	}
}
