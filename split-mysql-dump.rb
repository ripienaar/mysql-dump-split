#!/usr/bin/ruby
 
require 'optparse'
 
tables = []
ignore = []
dumpfile = ""

cmds = OptionParser.new do |opts|
  opts.banner = "Usage: split-mysql-dump.rb [options] [FILE]"

  opts.on("-s", "Read from stdin") do
    dumpfile = $stdin
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
        e = (Math.log(self)/Math.log(1024)).floor
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
 
    outfile = false
    table = ""
    db = ""
    linecount = tablecount = starttime = 0
 
    while (line = d.gets)
        if line =~ /^-- Table structure for table .(.+)./ or line =~ /^-- Dumping data for table .(.+)./
            table = $1
            linecount = 0
            tablecount += 1
 
            puts("\n\n") if outfile
 
            puts("Found a new table: #{table}")
            if (tables != [] and not tables.include?(table))
                puts"`#{table}` not in list, ignoring"
                table = ""
            elsif (ignore != [] and ignore.include?(table))
                puts"`#{table}` will be ignored"
                table = ""
            end 
            starttime = Time.now
            if table != ""
                outfile = File.new("#{db}_#{table}.sql", "w")
            end
        elsif line =~ /^USE .(.+).;/
            db = $1
            puts("Found a new db: #{db}")
        end
 
        if table != "" && outfile
            outfile.syswrite line
            linecount += 1
            elapsed = Time.now.to_i - starttime.to_i + 1
            print("    writing line: #{linecount} #{outfile.stat.size.bytes_to_human} in #{elapsed} seconds #{(outfile.stat.size / elapsed).bytes_to_human}/sec                 \r")
        end
    end
end
 
puts
