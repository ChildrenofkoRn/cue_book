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
      puts "Attention! Some lines were left unprocessed!"
      puts arr_parsed
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

  POSTFIX = /([^"']*)(?:["']?)/

  def parse_title
    prefix = /\s*TITLE\s/
    @headers_arr.each do |line|
      if line =~ /^#{prefix}.*/i
        self.title = line[/(?:#{prefix}+["']?)#{POSTFIX}/, 1]
                           .sub(/["']$/,'')
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_performer
    prefix = /\s*PERFORMER\s/
    @headers_arr.each do |line|
      if line =~ /^#{prefix}.*/i
        self.performer = line[/(?:#{prefix}+["']?)#{POSTFIX}/, 1]
                           .sub(/["']$/,'')
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_genre
    prefix = /REM\s+GENRE\s/
    @headers_arr.each do |line|
      if line =~ /^#{prefix}.*/i
        self.genre = line[/(?:#{prefix}+["']?)#{POSTFIX}/, 1]
                       .sub(/["']$/,'')
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_date
    prefix = /REM\s+DATE\s/
    @headers_arr.each do |line|
      if line =~ /^#{prefix}.*/i
        self.date = line[/(?:#{prefix}+["']?)#{POSTFIX}/, 1]
                      .sub(/["']$/,'')
        @headers_arr.delete(line)
        break
      end
    end
    date
  end

  def parse_comment
    prefix = /REM\s+COMMENT\s/
    @headers_arr.each do |line|
      if line =~ /^#{prefix}.*/i
        self.comment = line[/(?:#{prefix}+["']?)#{POSTFIX}/, 1]
                         .sub(/["']$/,'')
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_composer
    prefix = /REM\s+COMPOSER\s/
    @headers_arr.each do |line|
      if line =~ /^#{prefix}.*/i
        self.composer = line[/(?:#{prefix}+["']?)#{POSTFIX}/, 1]
                          .sub(/["']$/,'')
        @headers_arr.delete(line)
        break
      end
    end
  end

  def parse_file
    prefix = /\s*FILE\s/
    @headers_arr.each do |line|
      if line =~ /^#{prefix}.*/i
        self.file = line[/(?:#{prefix}+["']?)#{POSTFIX}\s+WAVE/, 1]
                      .sub(/["']$/,'')
        @headers_arr.delete(line)
        break
      end
    end
  end
end
