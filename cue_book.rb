require_relative 'cue_time'
require_relative 'cue_track'
require_relative 'cue_headers'

# TODO
# 1. Наверно стоит сделать индексы в треках сразу инстансами CueTime
# 2. Непонятно нужно ли нам хранить индексы треков если массив последовательный и легко нумеруется.
# 3. реализовать сравнение инстансов CueTime
#
# * Со временем реализовать добавление треков, те возможность увеличивать продолжительность CUE
# * Генерация нового CUE с 0
# * Подумать как иницилизировать объект, те создавать пустым или сразу скармливать файл или хеш?
#
class CueBook
  UTF_BOM = "\xEF\xBB\xBF"
  attr_reader :headers, :tracks, :save_path, :duration

  def initialize(save_path: nil, duration: nil)
    @save_path = set_save_path(save_path)
    @duration = duration ? CueTime.new(duration) : duration
    @headers = CueHeaders.new
    @tracks = []
    @file = nil
  end

  # FIXME нужно доработать CueTime, добавить операции сравнения
  def duration=(time_str)
    # duration = CueTime.new(time_str)
    #
    # @aka raise_duration_new_chap
    # if @tracks.nonzero? && duration <= @tracks.last.index
    #   raise "Total duration must be > start index last track!"
    # end
    # @duration = duration
    @duration = CueTime.new(time_str)
  end

  def set_save_path(save_path)
    if save_path && Dir.exist?(save_path)
      save_path
    else
      File.expand_path(File.dirname(__FILE__))
    end
  end

  def self.parse_from_file(path)
    object = allocate
    object.send(:initialize, save_path: File.dirname(path))

    object.load_cue(path)
    object.set_headers
    object.split_tracks
    object.parse_track
    object
  end

  def load_cue(path)
    @file = IO.read(path, :encoding => 'UTF-8')
    @file.delete! UTF_BOM if @file.include? UTF_BOM
  rescue Errno::ENOENT
    p "Error. File not found: #{path}"
    exit
  end

  def parse_track
    @tracks.map! do |track|
      cue_track = CueTrack.new
      cue_track.parse_track(track)
      cue_track.index = CueTime.new(cue_track.index)
      cue_track
    end
  end

  def set_headers
    headers_lines = get_headers_lines
    # DUP тк в CueHeaders мы его стираем по ходу парсинга
    # иначе не ворк next if index <= @headers_raw.size в split_tracks
    @headers = CueHeaders.parse_headers(headers_lines.dup)
  end

  def split_tracks
    track = []
    trigger = false

    @file.each_line do |line|
      trigger = true if line =~ /^\s+TRACK\s.*/i
      next unless trigger

      track.push line
      if line =~ /^\s+INDEX\s.*/
        @tracks.push track
        track = []
      end
    end

  end

  private

  def get_headers_lines
    headers_arr_lines = []
    @file.each_line do |line|
      headers_arr_lines.push line
      break if line =~ /^FILE\s.*/i
    end
    headers_arr_lines
  end

  # FIXME if duration new track > duration prev track
  # если добавляем нвоый трек в пустой cue?
  def add_chapter(index:, duration:, title:, author: nil)
    duration = CueTime.new(duration)

    if index > @tracks.size && !@tracks.size.zero?
      raise_duration_cue(index)
      duration = @duration
    elsif @tracks.size.zero?
      # nothing actions
    # if index < @tracks.size && @tracks.size > 0
    else
      # raise_duration_new_chap(index_new, index_prev)
      tracks_prev = @tracks[index - 1]
      tracks_prev_index = tracks_prev.index
      tracks_prev.index = CueTime.new(tracks_prev_index.dup) + duration
      duration = tracks_prev_index
    end

    track_new = CueTrack.new(number: index, title: title, author: author, index: duration)
    @tracks.insert(index - 1, track_new)
  end

  def raise_duration_cue(index)
    if @duration.nil?
      raise "Duration_cue must be int!" +
            "\nReason: Index new chapter > Total Tracks count: #{index} > #{@tracks.size}"
    end
  end

  def raise_duration_new_chap(index_new, index_prev)
    #TODO to realize
    if index_new >= index_prev
      raise "Duration new chapter too big!" +
            "\nReason: Index new chapter > Index prev chapter: #{index_new} > #{index_prev}"
    end
  end


  def add_track(index, track)
    # @tracks.insert(index, track)
  end
end

