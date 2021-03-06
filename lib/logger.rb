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
          `key` TEXT(50),
          `value` DOUBLE(25),
          `when` TEXT(25)
        );
        "
      )
    end

    # Adds a new entry to the log
    def log(key, value, date = false)
      date ||= Date.today.to_s

      @db.execute(
        "INSERT INTO log
        (`key`, `value`, `when`)
        VALUES
        (?, ?, ?)
        ",
        key,
        value,
        date
      )

      @latest_id = @db.last_insert_row_id
    end

    # Fetches entries from the log.
    #
    # Pass a block if you'd like to modify the query before it's
    # executed; that way, you don't have to use a load of boilerplate
    # SQL
    def select(key, since = false)
      sql = {
        :select => "SELECT `when`, `value`",
        :from   => "FROM log",
        :join   => "",
        :where  => "WHERE `key` = :key",
        :order  => "ORDER BY `when` DESC",
        :limit  => "",
        :params => { "key" => key }
      }

      if since
        sql[:where] += " AND `when` >= :since"
        sql[:params]["since"] = since
      end

      sql = sql.merge yield if block_given?

      params = sql.delete(:params)

      query = sql.values.join("\n")

      @db.execute query, params
    end

    # Returns the latest value for the given key
    def get_latest(key)
      select(key) { { :limit => "LIMIT 1" } }.first[1]
    end

    # Gets all of the values in the log for the given key
    def get_all(key, since = false)
      select(key)
    end

    # Calculates the average value for the given key
    def average(key, since = false)
      select(key, since) { { :select => "SELECT AVG(`value`)" } }.first[0]
    end
  end
end
