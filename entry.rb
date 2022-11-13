#!/usr/bin/env ruby

Warning[:deprecated] = false

require 'open3'
require 'shellwords'
require 'strscan'

files = ARGV[0].shellsplit.flat_map { |path| Dir.glob(path) }
args = ARGV[1].shellsplit

raise "No files files specified." if files.empty?

def escape(s)
  s.gsub(/\r/, '%0D')
   .gsub(/\n/, '%0A')
   .gsub(/]/, '%5D')
   .gsub(/;/, '%3B');
end

def assert_rest(rest)
  raise "Failed to parse rest of output: #{rest}" unless rest.empty?
end

def check_file(file, args)
  Open3.popen3('aspell', 'pipe', *args) do |stdin, stdout, stderr, wait_thread|
    errors = []

    begin
      extension = File.extname(file)
      code_block = false

      File.open(file, 'r').each_line.with_index do |line, i|
        if extension == '.tex'
          if line.match?(/^\s*\\begin{\s*lstlisting\s*}/)
            code_block = true
            next
          elsif line.match?(/^\s*\\end{\s*lstlisting\s*}/)
            code_block = false
            next
          elsif code_block
            next
          end
        end

        stdin.print '^'
        stdin.puts line.chomp

        loop do
          output = stdout.readline

          next if output.start_with?('@(#)')
          break if output == "\n"

          output = StringScanner.new(output)

          if type = output.scan(/(&|#|\*)/)
            if type == '*'
              output.skip(/\n/)
              next
            end

            output.skip(/\ /)
            word = output.scan(/[^\ \n]+/)
            output.skip(/\ /)
            if type == '&'
              suggestion_count = Integer(output.scan(/\d+/))
              output.skip(/\ /)
            else
              suggestion_count = 0
            end
            column = Integer(output.scan(/\d+/))

            suggestions = (0...suggestion_count).map { |i|
              output.skip(i.zero? ? /:/ : /,/)
              output.skip(/ /)

              output.scan(/[^,\n]+/)
            }

            output.skip(/\n/)

            puts "found some"
            errors << {
              word: word,
              line: i + 1,
              column: column - 1, # https://github.com/GNUAspell/aspell/issues/277
              suggestions: suggestions,
            }
          end

          assert_rest(output.rest)
        end
      end
    ensure
      stdin.close
    end

    assert_rest(stdout.read)

    status = wait_thread.value
    return errors if status.success?

    raise stderr.read
  rescue EOFError
    wait_thread.value
    raise stderr.read
  end
end

exit_status = 0

files.each do |file|
  puts "Checking spelling in file '#{file}':"

  errors = check_file(file, args)

  puts "Error checking in file '#{file}' complete"
  if errors.empty?
    puts "No errors found."
  else
    errors.each do |word:, line:, column:, suggestions:|
      message = <<~EOF
        Wrong spelling of “#{word}” found (line #{line}, column #{column}). Maybe you meant one of the following?

        #{suggestions.join(', ')}
      EOF

      puts "::error file=#{escape(file)},line=#{line},col=#{column}::#{escape(message)}"
    end

    exit_status = 1
  end
rescue => e
  puts "::error file=#{escape(file)}::#{e}"
  exit_status = 1
end

exit exit_status
