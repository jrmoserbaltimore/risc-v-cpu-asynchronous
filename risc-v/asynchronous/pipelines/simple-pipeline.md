Pipeline design
===============

The pipeline takes a minimalist approach.


```
[Fetch]
       [Decode]
               [Semaphore]
                          [Load]
	                        [Execute]
		                         [Store]
				                [Retire]
```
The Semaphore is an atomic locking operation to keep computations in-order,
activated before Load and on Retire.  In pseudocode:

```
RWSemaphore(Resource, Read, Write)
  if Read
    ReadLock(Resource)
  if Write
    WriteLock(Resource)

WriteLock(Resource)
  NoWaitWriteLock(Resource)

ReadLock(Resource)
  WaitForWriteUnlock(Resource)
```
No locking occurs before the first semaphore stage.  Write locks do not block
when taken because all read locks from earlier instructions will be closed out
before the current instruction reaches the Store stage.

Read locks block when a write lock is held on the resource.  This prevents the
Load until the write lock is released.  Write locks increment and decrement
for this reason:  multiple writes to a resource *without* reads will pipeline
multiple non-blocked write locks.  All writes must complete before a further
read can occur.  Only out-of-order execution environments need to track read
locks.

This behavior also means taking a read lock first avoids blocking on the
instruction's own write lock, avoiding read-and-write lock logic.

In the Retire stage, the write lock is atomically decremented.  When the write
lock hits zero, any instruction blocked at Semaphore waiting for that resource
continues its execution.

