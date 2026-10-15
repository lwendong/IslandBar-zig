const LyricsProtocol = @import("LyricsProtocol");

// Music owns lyric selection, timing and display state. The pure payload types
// and wire-format parsing helpers are shared with the Windows fetch adapter
// through this platform contract so the adapter never imports a Feature.
pub const line_capacity = LyricsProtocol.line_capacity;
pub const max_lines = LyricsProtocol.max_lines;
pub const line_enter_seconds = LyricsProtocol.line_enter_seconds;
pub const LyricLine = LyricsProtocol.LyricLine;
pub const Lyrics = LyricsProtocol.Lyrics;
pub const LyricSource = LyricsProtocol.LyricSource;
pub const lyricLineRollFor = LyricsProtocol.lyricLineRollFor;
pub const lyricLineChanged = LyricsProtocol.lyricLineChanged;
pub const parseLrc = LyricsProtocol.parseLrc;
pub const urlEncode = LyricsProtocol.urlEncode;
pub const decodeXmlEntities = LyricsProtocol.decodeXmlEntities;
pub const findFlatStringInArray = LyricsProtocol.findFlatStringInArray;
pub const findFlatIntegerInArray = LyricsProtocol.findFlatIntegerInArray;
pub const extractJsonLyricField = LyricsProtocol.extractJsonLyricField;
pub const extractLyricField = LyricsProtocol.extractLyricField;
pub const extractQqXmlLyric = LyricsProtocol.extractQqXmlLyric;
pub const reasonIsTransient = LyricsProtocol.reasonIsTransient;
pub const cSlice = LyricsProtocol.cSlice;
pub const smokeCheck = LyricsProtocol.smokeCheck;
