ExUnit.start()

# Configure ExVCR
ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes")
ExVCR.Config.filter_sensitive_data("APCA-API-KEY-ID", "<API_KEY>")
ExVCR.Config.filter_sensitive_data("APCA-API-SECRET-KEY", "<API_SECRET>")
