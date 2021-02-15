require 'plist'

class Hash
  def save_binary_plist(filename, options = {})
    Plist::Emit.save_plist(self, filename)
    `plutil -convert binary1 \"#{filename}\"`
  end
end

module Plist
  def self.parse_binary_xml(filename)
    `plutil -convert xml1 \"#{filename}\"`
    Plist.parse_xml(filename)
  end
end

