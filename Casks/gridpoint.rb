cask "gridpoint" do
  version "1.0.1"
  sha256 "5ea94cac82091c8dbb23fccc7c64576ce2b9a6424cac5b3e8a4510ca69008797"

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
