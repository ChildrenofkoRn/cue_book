class CueHeaders

  HEADERS_FAMOUS_REM = %w( genre date comment composer )
  HEADERS_FAMOUS = HEADERS_FAMOUS_REM + %w( performer title file )

  def header_template(type = :SIMPLE)
    {value: nil, type: type}.dup
  end

  def initialize
    @all = {}

    HEADERS_FAMOUS.each do |header|
      type = HEADERS_FAMOUS_REM.include?(header) ? :REM : :SIMPLE
      header_sym = header.to_sym
      @all[header_sym] = header_template(type)

      self.class.send(:define_method, header_sym) do
        @all[header_sym][:value]
      end

      self.class.send(:define_method, "#{header}_type".to_sym) do
        @all[header_sym][:type]
      end

      self.class.send(:define_method, "#{header}=".to_sym) do |data|
        @all[header_sym][:value] = data
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

    object.remove_instance_variable(:@headers_arr)
    return object
  end

  def get
    @all.dup
  end

  def set_announcer_for_title
    return if self.title.include?("[читает ")
    self.title = self.composer ? "#{self.title} [читает #{self.composer}]" : ""
  end

  private

  def parse_title
    @headers_arr.each do |line|
      if line =~ /^\s*TITLE\s.*/i
        self.title = line[/(?:")(.*)(?:")/, 1]
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_performer
    @headers_arr.each do |line|
      if line =~ /^\s*PERFORMER\s.*/i
        self.performer = line[/(?:")(.*)(?:")/, 1]
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_genre
    @headers_arr.each do |line|
      if line =~ /^REM\s+GENRE\s.*/i
        self.genre = line[/(?:REM\s+GENRE\s+"?)(.*)(?:"?)/, 1]
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_date
    @headers_arr.each do |line|
      if line =~ /^REM\s+DATE\s.*/i
        self.date = line[/(?:REM\s+DATE\s+"?)(.*)(?:"?)/, 1]
        @headers_arr.delete(line)
        break
      end
    end
    date
  end

  def parse_comment
    @headers_arr.each do |line|
      if line =~ /^REM\s+COMMENT\s.*/i
        self.comment = line[/(?:REM\s+COMMENT\s+")(.*)(?:")/, 1]
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_composer
    @headers_arr.each do |line|
      if line =~ /^REM\s+COMPOSER\s.*/i
        self.composer = line[/(?:REM\s+COMPOSER\s+")(.*)(?:")/, 1]
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_file
    @headers_arr.each do |line|
      if line =~ /^\s*FILE\s.*/i
        self.file = line[/(?:")(.*)(?:")/, 1]
        @headers_arr.delete(line)
        break
      end
    end
  end
end
