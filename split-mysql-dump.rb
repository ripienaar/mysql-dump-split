#!/usr/bin/ruby
 
if ARGV.length == 1
    dumpfile = ARGV.shift
    if dumpfile == '-'
        dumpfile = $stdin
    end
else
    puts("Please specify a dumpfile to process, or '-' for stdin")
    exit 1
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
 
            starttime = Time.now
            outfile = File.new("#{db}_#{table}.sql", "w")
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
