cask "gridpoint" do
  version "1.0.0"
  sha256 "22ad61ce38cfc3dd075e5de6d7030d2aaa85a4695543f59539419b9a1abb50b1"

  url "https://github.com/punkt-tokyo/gridpoint/releases/download/v#{version}/GridPoint-#{version}.zip"
  name "GridPoint"
  desc "Screen grid overlay for referencing locations during video calls"
  homepage "https://github.com/punkt-tokyo/gridpoint"

  app "GridPoint.app"

  zap trash: [
    "~/Library/Preferences/tokyo.punkt.GridPoint.plist",
    "~/Library/Application Support/GridPoint",
  ]
end
