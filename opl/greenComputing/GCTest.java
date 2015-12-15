/* Testing garbage collection behavior. 
* Suggested JVM options: -Xms2m -Xmx8m
* Copyright (c) 2003 by Dr. Herong Yang, herongyang.com
*/

/*
 * Modified by Anis Tello
 */
package opl.greenComputing;

class GCTest {
	static MyList objList = null;
	static int wait = 500; // milliseconds
	static int initSteps = 16; // 2 MB
	static int testSteps = 1;
	static int objSize = 128; // 1/8 MB

	public static void main(String[] arg) {
		if (arg.length > 0)
			initSteps = Integer.parseInt(arg[0]);
		if (arg.length > 1)
			testSteps = Integer.parseInt(arg[1]);
		objList = new MyList();
		Monitor m = new Monitor();
		m.setDaemon(true);
		m.start();
		new GC().start();
		myTest();
	}

	public static void myTest() {
		for (int m = 0; m < initSteps; m++) {
			mySleep(wait);
			objList.add(new MyObject());
		}
		for (int n = 0; n < 10 * 8 * 8 / testSteps; n++) {
			for (int m = 0; m < testSteps; m++) {
				mySleep(wait);
				objList.add(new MyObject());
			}
			for (int m = 0; m < testSteps; m++) {
				mySleep(wait);
				objList.removeTail();
				// objList.removeHead();
			}
		}
	}

	static void mySleep(int t) {
		try {
			Thread.sleep(t);
		} catch (InterruptedException e) {
			System.out.println("Interreupted...");
		}
	}

	static class MyObject {
		private static long count = 0;
		public MyObject next = null;
		public MyObject prev = null;

		public MyObject() {
			count++;
		}

		protected final void finalize() {
			count--;
		}

		static long getCount() {
			return count;
		}
	}

	static class MyList {
		static long count = 0;
		MyObject head = null;
		MyObject tail = null;

		static long getCount() {
			return count;
		}

		void add(MyObject o) {
			// add the new object to the head;
			if (head == null) {
				head = o;
				tail = o;
			} else {
				o.prev = head;
				head.next = o;
				head = o;
			}
			count++;
		}

		void removeTail() {
			if (tail != null) {
				if (tail.next == null) {
					tail = null;
					head = null;
				} else {
					tail = tail.next;
					tail.prev = null;
				}
				count--;
			}
		}

		void removeHead() {
			if (head != null) {
				if (head.prev == null) {
					tail = null;
					head = null;
				} else {
					head = head.prev;
					head.next = null;
				}
				count--;
			}
		}
	}

	static class Monitor extends Thread {
		public void run() {
			Runtime rt = Runtime.getRuntime();
			System.out.println("Time     Free           Dead");
			System.out.println("sec.    Mem. Per.        Obj.");
			long dt0 = System.currentTimeMillis() / 1000;
			while (true) {
				long tm = rt.totalMemory() / 1024;
				long fm = rt.freeMemory() / 1024;
				long ratio = (100 * fm) / tm;
				long dt = System.currentTimeMillis() / 1000 - dt0;
				long to = MyObject.getCount() * objSize;
				long ao = MyList.getCount() * objSize;
				System.out.println(dt + "         " + ratio + "%" + "             " + (to - ao));
				mySleep(wait);
			}
		}
	}

	static class GC extends Thread {
		public void run() {
			while (true) {
				try {
					GC.sleep(60000);
					System.gc();
				} catch (InterruptedException e) {
					System.out.println("Interreupted...");
				}
			}
		}
	}
}
