#!/usr/bin/env ruby
 
require 'optparse'
 
addNewlines = false
tables = []
ignore = []
dumpfile = ""

cmds = OptionParser.new do |opts|
  opts.banner = "Usage: split-mysql-dump.rb [options] [FILE]"

  opts.on("-s", "Read from stdin") do
  dumpfile = $stdin
  end
  
  opts.on("-n", "--newlines", "Add newlines between inserted rows") do
    addNewlines = true
  end

  opts.on("-t", '--tables TABLES', Array, "Extract only these tables") do |t|
    tables = t
  end
  
  opts.on("-i", '--ignore-tables TABLES', Array, "Ignore these tables") do |i|
    ignore = i
  end
  
  opts.on_tail("-h", "--help") do
  puts opts
  end

end.parse!

if dumpfile == ""
  dumpfile = ARGV.shift
  if not dumpfile
    puts "Nothing to do"
    exit 
  end
end

STDOUT.sync = true
 
class Numeric
  def bytes_to_human
    units = %w{B KB MB GB TB}
    e = self > 0 ? (Math.log(self)/Math.log(1024)).floor : 0
    s = "%.3f" % (to_f / 1024**e)
    s.sub(/\.?0*$/, units[e])
  end
end

if File.exist?(dumpfile)
  if dumpfile == $stdin
    d = $stdin
  else
    d = File.new(dumpfile, "r")
  end
 
  outfile = nil
  table = nil
  db = nil
  linecount = tablecount = starttime = 0
 
  while (line = d.gets)
    # Add newlines between inserted rows if desired.
    newLine = (addNewlines and line =~ /^INSERT INTO /) \
      ? line.gsub(/([^\\])\(/, "\\1\n(") \
      : line

    # Detect table changes
    if line =~ /^-- Table structure for table .(.+)./ or line =~ /^-- Dumping data for table .(.+)./
      is_new_table = table != $1
      table = $1

      # previous file should be closed
      if is_new_table
        outfile.close if outfile and !outfile.closed?

        puts("\n\nFound a new table: #{table}")

        if (tables != [] and not tables.include?(table))
          puts"`#{table}` not in list, ignoring"
          table = nil
        elsif (ignore != [] and ignore.include?(table))
          puts"`#{table}` will be ignored"
          table = nil
        else
          starttime = Time.now
          linecount = 0
          tablecount += 1
          outfile = File.new("#{db}/tables/#{table}.sql", "w")
          outfile.syswrite("USE `#{db}`;\n\n")
        end
      end
    elsif line =~ /^-- Current Database: .(.+)./
      db = $1
      table = nil
      outfile.close if outfile and !outfile.closed?
      Dir.mkdir(db)
      Dir.mkdir("#{db}/tables")
      outfile = File.new("#{db}/create.sql", "w")
      puts("\n\nFound a new db: #{db}")
    elsif line =~ /^-- Position to start replication or point-in-time recovery from/
      db = nil
      table = nil
      outfile.close if outfile and !outfile.closed?
      outfile = File.new("1replication.sql", "w")
      puts("\n\nFound replication data")
    end
 
    # Write line to outfile
    if outfile and !outfile.closed?
      outfile.syswrite(newLine)
      linecount += 1
      elapsed = Time.now.to_i - starttime.to_i + 1
      print("    writing line: #{linecount} #{outfile.stat.size.bytes_to_human} in #{elapsed} seconds #{(outfile.stat.size / elapsed).bytes_to_human}/sec                 \r")
    end
  end
end
 
puts
