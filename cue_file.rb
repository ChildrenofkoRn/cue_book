class CueFile

  UTF_BOM = "\xEF\xBB\xBF"

  def self.load_cue(path)
    file = IO.read(path, :encoding => 'UTF-8')
    file.delete(UTF_BOM)
  rescue Errno::ENOENT
    p "Error. File not found: #{path}"
    exit
  end

  def initialize(headers:, path2save:, cue_string:)
    @headers = headers
    @path2save = path2save
    @cue_string = cue_string
  end

  def save(save_path = @path2save)
    cue_string = UTF_BOM + @cue_string
    path = get_full_path(save_path)
    File.open(path, 'w') { |file| file.write cue_string }
  rescue => ex
    p "Something went wrong!"
    p "#{ex.class}: #{ex.message}"
    exit
  end

  private

  def get_filename
    template = '%<performer>s - %<title>s%<date>s%<timestamp>s.cue'

    date = @headers.date ? " [#{@headers.date}]" : ''
    time = Time.now.strftime("%Y%m%d_%H%M")
    timestamp = " #{time}"
    format(template, performer: @headers.performer,
           title: @headers.title,
           date: date,
           timestamp: timestamp )
  end

  def get_full_path(path)
    path + '/' + get_filename
  end
end
