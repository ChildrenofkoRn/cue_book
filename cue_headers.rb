class CueHeaders

  HEADERS_FAMOUS_REM = %w( genre date comment composer )
  HEADERS_FAMOUS = HEADERS_FAMOUS_REM + %w( performer title file )

    def header_template(type = :SIMPLE)
    {data: nil, type: type}.dup
  end

  def initialize
    HEADERS_FAMOUS.each do |header|
      type = HEADERS_FAMOUS_REM.include?(header) ? :REM : :SIMPLE

      instance_variable_set "@#{header}".to_sym, header_template(type)

      self.class.send(:define_method, header.to_sym) do
        instance_variable_get("@#{header}".to_sym)[:data]
      end

      self.class.send(:define_method, "#{header}_type".to_sym) do
        instance_variable_get("@#{header}".to_sym)[:type]
      end

      self.class.send(:define_method, "#{header}=".to_sym) do |data|
        instance_variable_get("@#{header}".to_sym)[:data] = data
      end
    end
  end

  def self.parse_headers(headers_arr)
    object = self.new
    object.instance_variable_set :@headers_arr, headers_arr

    HEADERS_FAMOUS.each do |header|
      object.send("parse_#{header}".to_sym)
    end

    arr_parsed = object.instance_variable_get :@headers_arr
    if arr_parsed.size > 0
      p "Attention! Some lines were left unprocessed!"
    end

    return object
  end

  def parse_title
    @headers_arr.each do |line|
      if line =~ /^\s*TITLE\s.*/i
        @title[:data] = line[/(?:")(.*)(?:")/,1]
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_performer
    @headers_arr.each do |line|
      if line =~ /^\s*PERFORMER\s.*/i
        @performer[:data] = line[/(?:")(.*)(?:")/,1]
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_genre
    @headers_arr.each do |line|
      if line =~ /^REM\s+GENRE\s.*/i
        @genre[:data] = line[/(?:REM\s+GENRE\s+"?)(.*)(?:"?)/,1]
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_date
    @headers_arr.each do |line|
      if line =~ /^REM\s+DATE\s.*/i
        @date[:data] = line[/(?:REM\s+DATE\s+"?)(.*)(?:"?)/,1]
        @headers_arr.delete(line)
        break
      end
    end
    date
  end

  def parse_comment
    @headers_arr.each do |line|
      if line =~ /^REM\s+COMMENT\s.*/i
        @comment[:data] = line[/(?:REM\s+COMMENT\s+")(.*)(?:")/,1]
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_composer
    @headers_arr.each do |line|
      if line =~ /^REM\s+COMPOSER\s.*/i
        @composer[:data] = line[/(?:REM\s+COMPOSER\s+")(.*)(?:")/,1]
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_file
    @headers_arr.each do |line|
      if line =~ /^\s*FILE\s.*/i
        @file[:data] = line[/(?:")(.*)(?:")/,1]
        @headers_arr.delete(line)
        break
      end
    end
  end
end
