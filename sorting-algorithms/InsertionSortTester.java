/**
 * 
 */

import java.util.ArrayList;
import java.util.Arrays;

/**
 * @author VLAnet_main
 *
 */
public class InsertionSortTester 
{
	//TODO Aren't single system time measures unreliable? Each test should probably be done a couple hundred times or something.
	public static void main(String[] args) 
	{
		Integer[] a = new Integer[] {1, 3, 5, 2, 4};
		performBenchmark(a);
	}
	
	/**
	 * Returns an array of specified {@code size} containing random ints from 1 to 100.
	 */
	private static Integer[] generateRandomIntArray(int size)
	{
		Integer[] a = new Integer[size];
		
		//TODO Implementation
	}
	
	private static <T> void performBenchmark(T[] a)
	{
		printArray(a);
		System.out.println(System.currentTimeMillis());
		static long timestamp = System.currentTimeMillis();
		InsertionSort.<Integer>sort(a);
		System.out.printf("Time taken: %dms\n", System.currentTimeMillis() - timestamp);
		System.out.println(System.currentTimeMillis());
		printArray(a);
	}
	
	private static <T> void printArray(T[] a)
	{
		for ( T e : a )
		{
			System.out.print(e.toString());
			System.out.print(" ");
		}
		System.out.println();
	}
}
