module PuppetAcceptance
  class IniFile
    def initialize file_as_string
      @contents = parse( file_as_string )
    end

    def [] key
      @contents[key]
    end

    def []= key, value
      @contents[key] = value
    end

    def parse file_as_string
      accumulator = Hash.new
      accumulator[:global] = Hash.new
      section = :global
      file_as_string.each_line do |line|
        case line
        when /^\s*\[\S+\]/
          # We've got a section header
          match = line.match(/^\s*\[(\S+)\].*/)
          section = match[1]
          accumulator[section] = Hash.new
        when /^\s*\S+\s*=\s*\S/
          # add a key value pair to the current section
          # will add it to the :global section if before a section header
          # note: in line comments are not support in puppet.conf
          raw_key, raw_value = line.split( '=' )
          key   = raw_key.strip
          value = raw_value.strip
          accumulator[section][key] = value
        end
        # comments, whitespace and lines without an '=' pass through
      end

      return accumulator
    end

    def to_s
      string = ''
      @contents.each_pair do |header, values|
        if header == :global
          values.each_pair do |key, value|
            string << "#{key} = #{value}\n"
          end
          string << "\n"
        else
          string << "[#{header}]\n"
          values.each_pair do |key, value|
            string << "  #{key} = #{value}\n"
          end
          string << "\n"
        end
      end
      return string
    end
  end
end
