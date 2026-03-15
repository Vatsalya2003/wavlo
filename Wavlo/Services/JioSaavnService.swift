import Foundation
import os.log

// MARK: - Response Wrapper

struct SaavnResponse<T: Decodable>: Decodable {
    let success: Bool?
    let data: T?
}

// MARK: - Flexible number (API may send Int or String)

struct FlexibleInt: Decodable {
    let value: Int
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let i = try? container.decode(Int.self) { value = i }
        else if let s = try? container.decode(String.self), let i = Int(s) { value = i }
        else { value = 0 }
    }
}

// MARK: - Image / Download URL

struct QualityURL: Decodable {
    let quality: String?
    let url: String?
}

// MARK: - Artist

struct SaavnArtistRef: Decodable {
    let id: String?
    let name: String?
    let image: [QualityURL]?
    let type: String?
    let url: String?
}

struct SaavnArtists: Decodable {
    let primary: [SaavnArtistRef]?
    let featured: [SaavnArtistRef]?
    let all: [SaavnArtistRef]?
}

// MARK: - Album

struct SaavnAlbumRef: Decodable {
    let id: String?
    let name: String?
    let url: String?
}

// MARK: - Song

struct SaavnSong: Decodable {
    let id: String?
    let name: String?
    let type: String?
    let year: String?
    private let durationFlex: FlexibleInt?
    let language: String?
    let url: String?
    let image: [QualityURL]?
    let downloadUrl: [QualityURL]?
    let artists: SaavnArtists?
    let album: SaavnAlbumRef?
    let hasLyrics: Bool?
    let label: String?
    private let playCountFlex: FlexibleInt?
    let explicitContent: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, type, year, language, url, image, artists, album, hasLyrics, label, explicitContent
        case downloadUrl
        case duration
        case playCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        type = try c.decodeIfPresent(String.self, forKey: .type)
        year = try c.decodeIfPresent(String.self, forKey: .year)
        durationFlex = try? c.decode(FlexibleInt.self, forKey: .duration)
        language = try c.decodeIfPresent(String.self, forKey: .language)
        url = try c.decodeIfPresent(String.self, forKey: .url)
        image = try c.decodeIfPresent([QualityURL].self, forKey: .image)
        downloadUrl = try c.decodeIfPresent([QualityURL].self, forKey: .downloadUrl)
        artists = try c.decodeIfPresent(SaavnArtists.self, forKey: .artists)
        album = try c.decodeIfPresent(SaavnAlbumRef.self, forKey: .album)
        hasLyrics = try c.decodeIfPresent(Bool.self, forKey: .hasLyrics)
        label = try c.decodeIfPresent(String.self, forKey: .label)
        playCountFlex = try? c.decode(FlexibleInt.self, forKey: .playCount)
        explicitContent = try c.decodeIfPresent(Bool.self, forKey: .explicitContent)
    }

    var durationSeconds: Int { durationFlex?.value ?? 0 }
}

// MARK: - Album (full)

struct SaavnAlbum: Decodable {
    let id: String?
    let name: String?
    let year: String?
    let image: [QualityURL]?
    let url: String?
    let songs: SaavnSongList?
    let artists: SaavnArtists?
}

struct SaavnSongList: Decodable {
    let results: [SaavnSong]?
}

// MARK: - Playlist

struct SaavnPlaylist: Decodable {
    let id: String?
    let name: String?
    let image: [QualityURL]?
    let url: String?
    let songs: SaavnSongList?
}

// MARK: - Artist (full)

struct SaavnArtist: Decodable {
    let id: String?
    let name: String?
    let image: [QualityURL]?
    let url: String?
    let songs: SaavnSongList?
}

// MARK: - Search Results (data has total, start, results)

struct SaavnSearchSongsData: Decodable {
    let total: Int?
    let start: Int?
    let results: [SaavnSong]?
}

struct SaavnSearchAlbumsData: Decodable {
    let results: [SaavnAlbum]?
}

struct SaavnSearchArtistsData: Decodable {
    let results: [SaavnArtistRef]?
}

struct SaavnPlaylistRef: Decodable {
    let id: String?
    let name: String?
    let title: String?
    var displayName: String? { name ?? title }
}

struct SaavnSearchPlaylistsData: Decodable {
    let total: Int?
    let start: Int?
    let results: [SaavnPlaylistRef]?
}

// MARK: - Modules (Home)

struct HomeModuleItem: Decodable {
    let id: String?
    let title: String?
    let subtitle: String?
    let type: String?
    let image: String?
    let url: String?
    let songs: [SaavnSong]?
    let results: [SaavnSong]?
    var songsOrResults: [SaavnSong]? { songs ?? results }
}

struct HomeModule: Decodable {
    let title: String?
    let subtitle: String?
    let position: Int?
    let source: String?
    let data: [HomeModuleItem]?
}

struct HomeModulesData: Decodable {
    let modules: [HomeModule]?
}

// MARK: - Lyrics

struct LyricsData: Decodable {
    let lyrics: String?
    let snippet: String?
    let copyright: String?
}

// MARK: - Service

actor JioSaavnService {

    private let logger = Logger(subsystem: "com.wavlo", category: "JioSaavn")
    private let session: URLSession
    private let baseURL: String

    /// User-Agent matching browser so Vercel/server treats the request like the working browser call.
    private static let browserUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    init(baseURL: String = Constants.JioSaavn.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    private func request(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(Self.browserUserAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func get<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        var components = URLComponents(string: baseURL + path)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else { throw JioSaavnError.invalidURL }
        let (data, response) = try await session.data(for: request(url: url))
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw JioSaavnError.httpStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(SaavnResponse<T>.self, from: data)
        if let value = wrapper.data { return value }
        throw JioSaavnError.emptyData
    }

    private func getData(path: String, queryItems: [URLQueryItem] = []) async throws -> Data {
        var components = URLComponents(string: baseURL + path)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else { throw JioSaavnError.invalidURL }
        logger.debug("JioSaavn request: \(url.absoluteString)")
        let (data, response) = try await session.data(for: request(url: url))
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let bodyPreview = String(data: data, encoding: .utf8).map { String($0.prefix(200)) } ?? ""
            logger.error("JioSaavn HTTP \(code), body preview: \(bodyPreview)")
            throw JioSaavnError.httpStatus(code)
        }
        return data
    }

    // MARK: - Search

    func searchSongs(query: String, page: Int = 0, limit: Int = 20) async throws -> [SaavnSong] {
        let path = "/search/songs"
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let data = try await getData(path: path, queryItems: queryItems)
        let decoder = JSONDecoder()
        // Try { data: { total, start, results } } first
        if let wrapper = try? decoder.decode(SaavnResponse<SaavnSearchSongsData>.self, from: data),
           let results = wrapper.data?.results {
            return results
        }
        // Fallback: { data: [ ...songs... ] } (data as direct array)
        if let wrapper = try? decoder.decode(SaavnResponse<[SaavnSong]>.self, from: data),
           let list = wrapper.data {
            return list
        }
        // Log decode failure for diagnostics
        do {
            _ = try decoder.decode(SaavnResponse<SaavnSearchSongsData>.self, from: data)
        } catch let decodingError as DecodingError {
            logger.error("JioSaavn searchSongs decode failed: \(String(describing: decodingError))")
        } catch {
            logger.error("JioSaavn searchSongs unexpected error: \(String(describing: error))")
        }
        throw JioSaavnError.emptyData
    }

    func searchAlbums(query: String, page: Int = 0, limit: Int = 20) async throws -> [SaavnAlbum] {
        let path = "/search/albums"
        let data: SaavnSearchAlbumsData = try await get(
            path: path,
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
        return data.results ?? []
    }

    func searchArtists(query: String, page: Int = 0, limit: Int = 20) async throws -> [SaavnArtistRef] {
        let path = "/search/artists"
        let data: SaavnSearchArtistsData = try await get(
            path: path,
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
        return data.results ?? []
    }

    func searchPlaylists(query: String, page: Int = 0, limit: Int = 10) async throws -> [SaavnPlaylistRef] {
        let path = "/search/playlists"
        let data: SaavnSearchPlaylistsData = try await get(
            path: path,
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
        return data.results ?? []
    }

    // MARK: - Song

    func getSongDetails(id: String) async throws -> SaavnSong {
        let path = "/songs/\(id)"
        let song: SaavnSong = try await get(path: path)
        guard song.id != nil else { throw JioSaavnError.emptyData }
        return song
    }

    // MARK: - Album

    func getAlbumDetails(id: String) async throws -> SaavnAlbum {
        let path = "/albums"
        let album: SaavnAlbum = try await get(path: path, queryItems: [URLQueryItem(name: "id", value: id)])
        return album
    }

    // MARK: - Playlist

    func getPlaylistDetails(id: String) async throws -> SaavnPlaylist {
        let path = "/playlists"
        let playlist: SaavnPlaylist = try await get(path: path, queryItems: [URLQueryItem(name: "id", value: id)])
        return playlist
    }

    // MARK: - Artist

    func getArtistDetails(id: String) async throws -> SaavnArtist {
        let path = "/artists/\(id)"
        let artist: SaavnArtist = try await get(path: path)
        return artist
    }

    func getArtistSongs(id: String, page: Int = 0) async throws -> [SaavnSong] {
        let path = "/artists/\(id)/songs"
        let data: SaavnSongList = try await get(path: path, queryItems: [URLQueryItem(name: "page", value: "\(page)")])
        return data.results ?? []
    }

    // MARK: - Lyrics

    func getLyrics(songId: String) async throws -> String? {
        let path = "/songs/\(songId)/lyrics"
        let data: LyricsData = try await get(path: path)
        return data.lyrics?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Suggestions

    func getSongSuggestions(songId: String, limit: Int = 10) async throws -> [SaavnSong] {
        let path = "/songs/\(songId)/suggestions"
        let data: SaavnSearchSongsData = try await get(
            path: path,
            queryItems: [URLQueryItem(name: "limit", value: "\(limit)")]
        )
        return data.results ?? []
    }

    // MARK: - Home Modules

    func getHomeData(languages: [String] = ["hindi", "english"]) async throws -> [HomeModule] {
        let path = "/modules"
        let lang = languages.joined(separator: ",")
        let data: HomeModulesData = try await get(path: path, queryItems: [URLQueryItem(name: "language", value: lang)])
        return data.modules ?? []
    }
}

enum JioSaavnError: Error {
    case invalidURL
    case httpStatus(Int)
    case emptyData
}

// MARK: - Helpers: SaavnSong → stream URL & artwork

extension SaavnSong {

    /// Best stream URL (320kbps preferred, else 160kbps).
    var bestStreamURL: String? {
        guard let list = downloadUrl, !list.isEmpty else { return nil }
        let url320 = list.last(where: { $0.quality?.contains("320") == true })?.url
        let url160 = list.last(where: { $0.quality?.contains("160") == true })?.url
        return url320 ?? url160 ?? list.last?.url
    }

    /// Best artwork URL (500x500 preferred).
    var bestImageURL: String? {
        guard let list = image, !list.isEmpty else { return nil }
        return list.last(where: { $0.quality?.contains("500") == true })?.url
            ?? list.last?.url
    }

    var primaryArtistName: String {
        artists?.primary?.map(\.name).compactMap { $0 }.joined(separator: ", ") ?? ""
    }

    var albumName: String {
        album?.name ?? ""
    }

    var durationInt: Int { durationSeconds }

    var playCountString: String {
        playCountFlex.map { String($0.value) } ?? ""
    }

    func toSong() -> Song {
        Song(
            id: id ?? "",
            title: name ?? "",
            artistName: primaryArtistName,
            albumName: albumName,
            genre: language ?? "",
            streamURL: bestStreamURL ?? "",
            artworkURL: bestImageURL ?? "",
            duration: durationInt,
            tags: [language ?? ""].filter { !$0.isEmpty },
            language: language ?? "",
            hasLyrics: hasLyrics ?? false,
            jiosaavnPlayCount: playCountString
        )
    }
}
