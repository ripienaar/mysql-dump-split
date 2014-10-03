require 'mysql_dump_split/version'

class Numeric
  def bytes_to_human
    units = %w{B KB MB GB TB}
    e = self > 0 ? (Math.log(self)/Math.log(1024)).floor : 0
    s = "%.3f" % (to_f / 1024**e)
    s.sub(/\.?0*$/, units[e])
  end
end

class MysqlDumpSplit
  attr_accessor :tables, :ignore, :use_database
  attr_reader :dumpfile

  def initialize
    @tables = []
    @ignore = []
    @use_database = nil
    @dumpfile = nil
  end

  def dumpfile=(dumpfile)
    @dumpfile = open(dumpfile)
  end

  def split!
    return unless File.exist?(@dumpfile)
    @current_db = @use_database

    @line_count = @table_count = @start_time = 0

    @current_table = @outfile = nil

    while (line = @dumpfile.gets) do

      case line
        when /^-- Table structure for table .(.+)./, /^-- Dumping data for table .(.+)./, /^# Dump of table.(.+)/
          is_new_table = (@current_table != $1)
          table = $1

          new_table(table) if is_new_table
        when /^-- Current Database: .(.+)./
          @current_db = $1
          @current_table = nil

          close_outfile

          Dir.mkdir(@current_db)
          Dir.mkdir("#{@current_db}/tables")
          self.outfile = "#{@current_db}/create.sql"
          puts("\n\nFound a new db: #{@current_db}")
        when /^-- Position to start replication or point-in-time recovery from/
          @current_db = nil
          @current_table = nil

          close_outfile

          self.outfile = '1replication.sql'
          puts("\n\nFound replication data")
        else
          write(line)
      end
    end

    puts
  end

  def outfile=(name)
    @outfile = File.new(name, 'w')
  end

  def write(line)
    return unless @outfile
    return if @outfile.closed?

    @outfile.syswrite(line)
    @line_count += 1
    elapsed = Time.now.to_i - @start_time.to_i + 1
    print("    writing line: #{@line_count} #{@outfile.stat.size.bytes_to_human} in #{elapsed} seconds #{(@outfile.stat.size / elapsed).bytes_to_human}/sec                 \r")
  end

  def close_outfile
    @outfile.close if @outfile and !@outfile.closed?
    @outfile = nil
  end

  def included?(table)
    @tables.empty? or @tables.include?(table)
  end

  def ignored?(table)
    ! @ignore.empty? && @ignore.include?(table)
  end

  def new_table(table)
    close_outfile

    puts("\n\nFound a new table: #{table}")

    if not included?(table)
      puts "`#{table}` not in list, ignoring"
    elsif ignored?(table)
      puts "`#{table}` will be ignored"
    else
      @start_time = Time.now
      @line_count = 0
      @table_count += 1
      path = tables_path
      Dir.mkdir(path) unless File.exists?(path)
      self.outfile = "#{path}/#{table}.sql"

      if db = @current_db
        @outfile.syswrite("USE `#{db}`;\n\n")
      end
    end

    @current_table = table
  end

  def tables_path
    [@current_db, 'tables'].compact.join('/')
  end

  private

  def open(dumpfile)
    if dumpfile == $stdin
      $stdin
    elsif dumpfile
      File.new(dumpfile, "r:binary")
    end
  end
end
