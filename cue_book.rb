require_relative 'cue_time'
require_relative 'cue_track'
require_relative 'cue_headers'

# TODO
# Похоже стоит создать класс Playlist, который и будет заниматься треками
# пока что где треки где главы => выбрать одно - главы
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

  def duration=(time_str)
    duration = CueTime.new(time_str)

    if @tracks.size.nonzero? && duration <= @tracks.last.index
      raise "Total duration must be > start index last track!" +
            "\nIndex last track = #{@tracks.last.index}"
    end
    @duration = duration
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
    object.instance_variable_set :@file, nil
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
    @headers = CueHeaders.parse_headers(get_headers_lines)
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

  # REFACTOR
  def add_chapter(number:, duration:, title:, author: nil)
    duration_new_chapter = CueTime.new(duration)
    new_index = CueTime.new
    number = number.abs

    # If the chapter is added to the end after the existing tracks
    if number > @tracks.size && @tracks.size.nonzero?
      new_index, number = *helper_adding_last_track(number, duration_new_chapter)

    # If a chapter is added to an empty CUE, those will be the first chapter
    elsif @tracks.size.zero?
      @duration = duration_new_chapter

    # If a chapter is added to the beginning of a CUE, that already contains chapters
    elsif @tracks.size.nonzero? && number == 1
      tracks_next = @tracks[number - 1]
      tracks_next_index = tracks_next.index.dup + duration_new_chapter
      raise_duration_chapter(@tracks[1].index, tracks_next_index)
      tracks_next.index = tracks_next_index

    # If a chapter is added between chapters
    # if index < @tracks.size && @tracks.size > 0
    else
      tracks_next = @tracks[number - 1]
      new_index = (new_index + tracks_next.index) - duration_new_chapter
      raise_duration_chapter(new_index, @tracks[number - 2].index)
    end

    renumber_tracks(number) if number <= @tracks.size
    track_new = CueTrack.new(number: number, title: title, author: author, index: new_index)
    @tracks.insert(number - 1, track_new)
  end

  def insert_chapter(number:, duration:, title:, author: nil)
    duration_new_chapter = CueTime.new(duration)
    new_index = CueTime.new
    number = number.abs

    # If the chapter is added to the end after the existing tracks
    if number > @tracks.size && @tracks.size.nonzero?
      new_index, number = *helper_adding_last_track(number, duration_new_chapter)

    # If a chapter is added to an empty CUE, those will be the first chapter
    elsif @tracks.size.zero?
      @duration = duration_new_chapter

    # If a chapter is added to the beginning of a CUE, that already contains chapters
    elsif @tracks.size.nonzero? && number == 1
      @duration = @duration + duration_new_chapter unless @duration.nil?

    # If a chapter is added between chapters
    # if index < @tracks.size && @tracks.size > 0
    else
      tracks_next = @tracks[number - 1]
      new_index = new_index + tracks_next.index
      @duration = @duration + duration_new_chapter unless @duration.nil?
    end

    reindex_tracks(number, duration_new_chapter) if number <= @tracks.size
    renumber_tracks(number) if number <= @tracks.size
    track_new = CueTrack.new(number: number, title: title, author: author, index: new_index)
    @tracks.insert(number - 1, track_new)
  end

  private

  def helper_adding_last_track(number, duration_new_chapter)
    raise_duration_cue(number)
    new_index = CueTime.new + @duration
    @duration + duration_new_chapter
    number = @tracks.size + 1

    [new_index, number]
  end

  def delete_chapter_info

  end

  def erase_chapter

  end

  def reindex_tracks(start_number, added_duration)
    @tracks.each do |track|
      next if track.number < start_number
      track.index + added_duration
    end
  end

  def renumber_tracks(start_number)
    @tracks.each do |track|
      next if track.number < start_number
      track.number += 1
    end
  end

  def get_headers_lines
    headers_arr_lines = []
    @file.each_line do |line|
      headers_arr_lines.push line
      break if line =~ /^FILE\s.*/i
    end
    headers_arr_lines
  end

  def raise_duration_cue(number)
    if @duration.nil?
      raise "Total Duration CUE must be set!" +
            "\nReason: Number new chapter > Total chapters count: #{number} > #{@tracks.size}" +
            "\nUnfortunately, CUE does not store the full duration." +
            "\nFor this operation, it must be set e.g: cue.duration = '111:01:10'" +
            "\n\t* And it should also be greater than the index of the last track."
    end
  end

  def raise_duration_chapter(index_next, index_prev)
    if index_next <= index_prev
      raise "Duration chapter too big!" +
            "\nReason: Index next chapter <= Index prev chapter: #{index_next} <= #{index_prev}"
    end
    if (index_next.frames - index_prev.frames) <= 75 * 5
      p 'Attention! You will get a chapter duration less than 5 seconds!'
      p 'Maybe you are doing something wrong.'
    end
  end
end

