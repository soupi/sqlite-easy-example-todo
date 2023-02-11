# A minimal todo list app example with sqlite-easy

This is a very simple example of the
[sqlite-easy](https://hackage.haskell.org/package/sqlite-easy) package.

- Read the [sqlite-easy docs](https://hackage.haskell.org/package/sqlite-easy-1.0.0.0/docs/Database-Sqlite-Easy.html)
- See the example [source code](src/Main.hs)

## How to run

```sh
cabal run todo-sqlite-easy -- <command>
```

or copy the executable to the current directory with

```sh
cp $(cabal list-bin todo-sqlite-easy) todo-sqlite-easy
```

and then run

```sh
./todo-sqlite-easy <command>
```

## What does it look like

```sh
>  ./todo-sqlite-easy
Todo list app

Set the connection string using the DB environment variable.

Commands:

	list		List all tasks
	add <task>	Add a task
	delete <id>	Delete a task by id
	clear		Delete all tasks

> ./todo-sqlite-easy add read the sqlite-easy docs
New task with id (1)
> ./todo-sqlite-easy add clone the sqlite-easy-example-todo repo
New task with id (2)
> ./todo-sqlite-easy add cabal build
New task with id (3)
> ./todo-sqlite-easy add play with the source code at src/Main.hs
New task with id (4)
> ./todo-sqlite-easy add "???"
New task with id (5)
> ./todo-sqlite-easy add "fun!"
New task with id (6)
> ./todo-sqlite-easy list
6 tasks.
	(1) read the sqlite-easy docs
	(2) clone the sqlite-easy-example-todo repo
	(3) cabal build
	(4) play with the source code at src/Main.hs
	(5) ???
	(6) fun!
> ./todo-sqlite-easy delete 5
Task deleted.
> ./todo-sqlite-easy list
5 tasks.
	(1) read the sqlite-easy docs
	(2) clone the sqlite-easy-example-todo repo
	(3) caal build
	(4) play with the source code at src/Main.hs
	(6) fun!
```
