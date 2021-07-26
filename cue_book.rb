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
  attr_reader :headers, :tracks

  def initialize(file, duration_cue = nil)
    @file = file
    @duration_cue = duration_cue
    @raw = nil
    @headers_raw = []
    @headers = []
    @tracks = []
    parse_cue
  end

  def load_cue
    @raw = IO.read(@file, :encoding => 'UTF-8')
    @raw.delete! UTF_BOM if @raw.include? UTF_BOM
  end

  def parse_cue
    load_cue
    set_headers
    split_tracks
    parse_track
  end

  def parse_track
    @tracks.map! do |track|
      cue_track = CueTrack.new
      cue_track.parse_track(track)
      cue_track
    end
  end

  def set_headers
    get_headers
    # DUP тк в CueHeaders мы его стираем по ходу парсинга
    # иначе не ворк next if index <= @headers_raw.size в split_tracks
    @headers = CueHeaders.new(@headers_raw.dup)
  end

  def get_headers
    @raw.each_line do |line|
      @headers_raw.push line
      break if line =~ /^FILE\s.*/i
    end
  end

  def split_tracks
    index = 0
    track = []

    @raw.each_line do |line|
      index += 1
      next if index <= @headers_raw.size
      track.push line

      if line =~ /^\s+INDEX\s.*/
        @tracks.push track
        track = []
      end
    end

  end

  # FIXME if duration new track > duration prev track
  # если добавляем нвоый трек в пустой cue?
  def add_chapter(index:, duration:, title:, author: nil)
    duration = CueTime.new(duration)

    if index > @tracks.size && !@tracks.size.zero?
      raise_duration_cue(index)
      duration = @duration_cue
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
    if @duration_cue.nil?
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

