(*****************************************************************************

  Liquidsoap, a programmable audio stream generator.
  Copyright 2003-2010 Savonet team

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details, fully stated in the COPYING
  file at the root of the liquidsoap distribution.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

 *****************************************************************************)

(** Multithreading utilities *)

(** {1 Thread wrapper}
  Give names to threads, and forbid them to raise an exception;
  if that happens, the thread dies anyway but it is logged and [main]
  will notice it.
  The main process is expected to run [main] after having launched
  the needed threads: that function will sleep until a thread
  raises an exception. *)
val create : ('a -> unit) -> 'a -> string -> Thread.t
val main : unit -> unit
val shutdown : unit -> unit

(** Wait for the threads to terminate,
  * never return if some thread keeps running. *)
val join_all : unit -> unit

(** Check if a thread is running. *)
val running : string -> Thread.t -> bool

(** {1 Multi-tasking scheduler} *)

(** Priorities for the different scheduler usages. *)
type priority =
  | Blocking       (** For example a last.fm submission. *)
  | Maybe_blocking (** Request resolutions vary a lot. *)
  | Non_blocking   (** Non-blocking tasks like the server. *)

(** task scheduler *)
val scheduler : priority Duppy.scheduler

(** Ask for a special queue that treats exclusively non blocking tasks.
  * This is need for things such as the server or harbor to run smoothly. *)
val need_non_blocking_queue : unit -> unit

(** {1 Misc} *)

(** Waits for [f()] to become true on condition [c].
  * The mutex [m] protecting data accessed by [f] is in the same state before
  * and after the call. *)
val wait : Condition.t -> Mutex.t -> (unit -> bool) -> unit

(** Make a function work in critical section, protected by a given lock. *)
val mutexify : Mutex.t -> ('a -> 'b) -> ('a -> 'b)

(** [finalize ~k f] calls [f] and returns it result,
  * and always executes [k], even when [f] raises an exception. *)
val finalize : k:(unit -> unit) -> (unit -> 'a) -> 'a

(** Tests whether a mutex is locked, without blocking.
  * We cannot check on Win32, where [true] is always returned:
  * it always "seems" OK, we don't raise false alarms.
  * This is meant to be used for assertions. *)
val seems_locked : Mutex.t -> bool

(** Thread-safe equivalent to Lazy.lazy_from_fun. *)
val lazy_cell : (unit -> 'a) -> (unit -> 'a)
