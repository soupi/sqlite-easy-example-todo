-- | A primitive todo list app as an example of sqlite-easy.

{-# language OverloadedStrings #-}
{-# language LambdaCase #-}
{-# language BlockArguments #-}

module Main where

import Database.Sqlite.Easy
import Data.Functor ((<&>))
import qualified Data.Text as Text
import qualified Data.Text.IO as Text
import System.Environment (getArgs, lookupEnv)

main :: IO ()
main = do
  connStr <- maybe "/tmp/temp_todo_sqlite-easy.db" fromString <$> lookupEnv "DB"
  db <- mkDB connStr
  input <- getArgs
  act db input

-- | Handle input and act accordingly
act :: DB -> [String] -> IO ()
act db = \case
  ["list"] -> do
    tasks <- getTasks db
    putStrLn $ show (length tasks) <> " tasks."
    getTasks db >>= mapM_ \(id', task) -> do
      putStr $ "\t(" <> show id' <> ") "
      Text.putStrLn task

  "add" : text -> do
    let task = Text.pack (unwords text)
    id' <- insertTask db task
    putStrLn $ "New task with id (" <> show id' <> ")"

  ["delete", idStr] -> do
    let id' = read idStr
    exists <- deleteTaskById db id'
    if exists
      then putStrLn "Task deleted."
      else errorMsg "A task by this id does not exist" ("(" <> show id' <> ")")

  ["clear"] -> do
    deleteTasks db
    putStrLn "Tasks deleted."

  _ ->
    putStrLn $ unlines
      [ "Todo list app"
      , ""
      , "Set the connection string using the DB environment variable."
      , ""
      , "Commands:"
      , ""
      , "\tlist\t\tList all tasks"
      , "\tadd <task>\tAdd a task"
      , "\tdelete <id>\tDelete a task by id"
      , "\tclear\t\tDelete all tasks"
      ]

errorMsg :: String -> String -> a
errorMsg msg extra =
  error ("*** Error: " <> msg <> " - " <> extra)

-----------------
-- * Database

-- ** Handler

-- | Handler API type
data DB
  = DB
    { getTasks :: IO [(Id, Task)]
    , insertTask :: Task -> IO Id
    , deleteTaskById :: Id -> IO Bool
    , deleteTasks :: IO ()
    }

type Task = Text
type Id = Int64

-- | Handler smart constructor
mkDB :: ConnectionString -> IO DB
mkDB connectionString = do
  pool <- createSqlitePool connectionString
  withPool pool runMigrations
  pure DB
    { getTasks = getTasksFromDb pool
    , insertTask = insertTaskToDb pool
    , deleteTaskById = deleteTaskByIdFromDb pool
    , deleteTasks = deleteTasksFromDb pool
    }

---------------------
-- ** Migrations

-- | Migrations action
runMigrations :: SQLite ()
runMigrations = migrate migrations migrateUp migrateDown

-- | Migrations list
migrations :: [MigrationName]
migrations =
  [ "task-table"
  ]

-- | Migrations up step
migrateUp :: MigrationName -> SQLite ()
migrateUp = \case
  "task-table" ->
    void (run "CREATE TABLE task(id INTEGER PRIMARY KEY AUTOINCREMENT, task TEXT)")
  unknown ->
    errorMsg "Unexpected migration" (show unknown)

-- | Migrations down step
migrateDown :: MigrationName -> SQLite ()
migrateDown = \case
  "task-table" ->
    void (run "DROP TABLE task")
  unknown ->
    errorMsg "Unexpected migration" (show unknown)

---------------------------
-- ** Database actions

-- | Retrieve all of the tasks from the database
getTasksFromDb :: Pool Database -> IO [(Id, Task)]
getTasksFromDb pool = do
  withPool pool (run "SELECT id, task FROM task")
    <&> map \case
      [SQLInteger id', SQLText task] ->
        (id', task)
      result ->
        errorMsg "Unexpected row" (show result)

-- | Insert a new task into the database and get its id
insertTaskToDb :: Pool Database -> Task -> IO Id
insertTaskToDb pool task =
  withPool pool do
    transaction do
      void $ runWith "INSERT INTO task(task) VALUES (?)" [SQLText task]
      result <- run "SELECT id FROM task ORDER BY id DESC LIMIT 1"
      case result of
        [[SQLInteger lastId]] -> pure lastId
        _ -> errorMsg "Unexpected row" (show result)

-- | Delete a task by its id if it exists.
--   Return whether there was a task by that id or not
deleteTaskByIdFromDb :: Pool Database -> Id -> IO Bool
deleteTaskByIdFromDb pool id' =
  withPool pool do
    transaction do
      [[SQLInteger count]] <-
        runWith "SELECT COUNT(*) FROM task WHERE id = ?" [SQLInteger id']
      void $ runWith "DELETE FROM task WHERE id = ?" [SQLInteger id']
      pure (count > 0)

-- | Delete all tasks.
deleteTasksFromDb :: Pool Database -> IO ()
deleteTasksFromDb pool =
  withPool pool do
    transaction do
      void $ run "DELETE FROM task"
      void $ run "UPDATE SQLITE_SEQUENCE SET SEQ=0 WHERE NAME='task'"
