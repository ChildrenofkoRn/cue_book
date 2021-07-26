class CueHeaders

  HEADERS_FAMOUS = %w( genre date comment performer title file )

  # attr_accessor *HEADERS_ALLOW.map(&:to_sym)

  def header_template
    {data: nil, type: :simple}.dup
  end

  HEADER_TEMPLATE = {data: nil, type: :simple}.freeze

  def initialize(headers_arr)
    @headers_arr = headers_arr
    parse_headers
  end

  def parse_headers
    HEADERS_FAMOUS.each do |header|
      instance_variable_set "@#{header}".to_sym, send("parse_#{header}".to_sym)

      self.class.define_method(header.to_sym) do
        instance_variable_get("@#{header}".to_sym)[:data]
      end

      self.class.define_method("#{header}_type".to_sym) do
        instance_variable_get("@#{header}".to_sym)[:type]
      end

      self.class.define_method("#{header}=".to_sym) do |data|
        instance_variable_get("@#{header}".to_sym)[:data] = data
        # header_hash = instance_variable_get("@#{header}".to_sym)
        # header_hash[:data] = data
        # тк как объект header_hash у нас тот же что и в "@#{header}" то нет надоности его сохранять наппрямую
        # instance_variable_set("@#{header}".to_sym, header_hash)
      end
    end

    if @headers_arr.size > 0
      p "Attention! Some lines were left unprocessed!"
    end
  end

  def parse_title
    title = header_template
    @headers_arr.each do |line|
      if line =~ /^\s*TITLE\s.*/i
        title[:data] = line[/(?:")(.*)(?:")/,1]
        @headers_arr.delete(line)
        break
      end
    end
    title
  end

  def parse_performer
    author = header_template
    @headers_arr.each do |line|
      if line =~ /^\s*PERFORMER\s.*/i
        author[:data] = line[/(?:")(.*)(?:")/,1]
        @headers_arr.delete(line)
        break
      end
    end
    author
  end

  def parse_genre
    genre = header_template
    @headers_arr.each do |line|
      if line =~ /^REM\s+GENRE\s.*/i
        genre[:data] = line[/(?:REM\s+GENRE\s+"?)(.*)(?:"?)/,1]
        genre[:type] = :REM
        @headers_arr.delete(line)
        break
      end
    end
    genre
  end

  def parse_date
    date = header_template
    @headers_arr.each do |line|
      if line =~ /^REM\s+DATE\s.*/i
        date[:data] = line[/(?:REM\s+DATE\s+"?)(.*)(?:"?)/,1]
        date[:type] = :REM
        @headers_arr.delete(line)
        break
      end
    end
    date
  end

  def parse_comment
    comment = header_template
    @headers_arr.each do |line|
      if line =~ /^REM\s+COMMENT\s.*/i
        comment[:data] = line[/(?:REM\s+COMMENT\s+")(.*)(?:")/,1]
        comment[:type] = :REM
        @headers_arr.delete(line)
        break
      end
    end
    comment
  end

  def parse_file
    file = header_template
    @headers_arr.each do |line|
      if line =~ /^\s*FILE\s.*/i
        file[:data] = line[/(?:")(.*)(?:")/,1]
        @headers_arr.delete(line)
        break
      end
    end
    file
  end

  def render
    headers = []
    HEADERS_FAMOUS.each do |header|

      data = instance_variable_get("@#{header}".to_sym)[:data]
      type = instance_variable_get("@#{header}".to_sym)[:type]

      line = if type == :REM
               'REM %s "%s"' % [header.upcase, data]
             else
               '%s "%s"' % [header.upcase, data]
             end
      headers.push line
    end
    headers.join("\n")
  end

end
