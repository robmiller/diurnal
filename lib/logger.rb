require 'sqlite3'
require 'date'

module Diurnal
  class Logger
    attr_reader :file, :db, :latest_id

    # Given a database file, opens it for reading and writing, and runs
    # the install if necessary.
    def initialize(file)
      raise ArgumentError unless File.readable? file

      @file = file

      @db = SQLite3::Database.new(file)

      install unless installed?
    end

    # Checks if the required database tables have been created.
    def installed?
      count = @db.get_first_value(
        "SELECT COUNT(*)
         FROM sqlite_master
         WHERE type = 'table'
         AND name = 'log'
        "
      )

      count.to_i > 0
    end

    # Creates the necessary database tables
    def install
      @db.execute(
        "CREATE TABLE log (
          `id` INTEGER PRIMARY KEY,
          `value` DOUBLE(25),
          `when` TEXT(25)
        );
        "
      )
    end

    # Adds a new entry to the log
    def log(value)
      @db.execute(
        "INSERT INTO log
        (`value`, `when`)
        VALUES
        (?, date('now'))
        ",
        value
      )

      @latest_id = @db.last_insert_row_id
    end

    # Returns the latest value
    def get_latest
      @db.get_first_value(
        "SELECT value
        FROM log
        ORDER BY `when` DESC
        LIMIT 1
        "
      ).to_f
    end

    # Gets all of the values in the log
    def get_all
      @db.execute(
        "SELECT `when`, `value`
        FROM log
        ORDER BY `when` ASC
        "
      )
    end
  end
end
