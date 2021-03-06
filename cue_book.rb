require_relative 'cue_time'
require_relative 'cue_track'
require_relative 'cue_headers'
require_relative 'cue_tracklist'
require_relative 'cue_render'
require_relative 'cue_file'
require_relative 'cue_error'

# TODO
#
#
class CueBook
  attr_reader :headers, :save_path, :tracklist

  def initialize(save_path: nil, duration: nil)
    @save_path = set_save_path(save_path)
    @headers   = CueHeaders.new
    @tracklist = CueTracklist.new(duration)
  end

  def self.parse_from_file(path)
    object = allocate
    object.send(:initialize, save_path: File.dirname(path))

    file = CueFile.load_cue(path)
    object.instance_variable_set(:@file, file)
    object.send(:set_headers)
    object.send(:parse_track)
    object.remove_instance_variable(:@file)
    object
  end

  def duration
    @tracklist.duration
  end

  def duration=(time_str)
    @tracklist.duration = (time_str)
  end

  def render
    @headers.set_announcer_for_title
    CueRender.new(headers: @headers, tracks: @tracklist.tracks).render
  end

  def save
    file = CueFile.new(headers: @headers, path2save: @save_path, cue_string: self.render)
    file.save
  end

  private

  def set_save_path(save_path)
    if save_path && Dir.exist?(save_path)
      save_path
    else
      File.expand_path(File.dirname(__FILE__))
    end
  end

  def set_headers
    @headers = CueHeaders.parse_headers(get_headers_lines)
  end

  def parse_track
    tracks = split_tracks

    tracks.map! do |track|
      cue_track = CueTrack.parse_track(track)
      cue_track.index = CueTime.new(cue_track.index)
      cue_track
    end
    @tracklist.load_tracks(tracks)
  end

  def split_tracks
    tracks = []
    track = []
    trigger = false

    @file.each_line do |line|
      trigger = true if line =~ /^\s+TRACK\s.*/i
      next unless trigger

      track.push line
      if line =~ /^\s+INDEX\s.*/
        tracks.push track
        track = []
      end
    end
    tracks
  end

  def get_headers_lines
    headers_arr_lines = []
    @file.each_line do |line|
      headers_arr_lines.push line.chomp
      break if line =~ /^FILE\s.*/i
    end
    headers_arr_lines
  end
end

