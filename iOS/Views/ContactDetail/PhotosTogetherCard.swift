import SwiftUI
import Photos

struct PhotosTogetherCard: View {
    let contactName: String
    @State private var photoCount: Int = 0
    @State private var thumbnails: [UIImage] = []
    @State private var permissionGranted = false
    @State private var loading = true

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary)

                    Text("PHOTOS TOGETHER")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    if photoCount > 0 {
                        Text("\(photoCount) PHOTOS")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }

                if loading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(AppTheme.textMuted)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else if !permissionGranted {
                    Button {
                        requestPhotoAccess()
                    } label: {
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                            Text("GRANT PHOTO ACCESS")
                                .font(AppTheme.caption)
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                        )
                    }
                } else if photoCount == 0 {
                    Text("NO PHOTOS FOUND WITH \(contactName.uppercased())")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                } else {
                    // Thumbnail grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 4), spacing: 3) {
                        ForEach(0..<min(thumbnails.count, 8), id: \.self) { index in
                            Image(uiImage: thumbnails[index])
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }

                        // "More" tile
                        if photoCount > 8 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                )
                                .overlay(
                                    Text("+\(photoCount - 8)")
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundStyle(AppTheme.textSecondary)
                                )
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
        .onAppear {
            checkAndLoadPhotos()
        }
    }

    private func checkAndLoadPhotos() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            permissionGranted = true
            loadPersonPhotos()
        case .notDetermined:
            requestPhotoAccess()
        default:
            permissionGranted = false
            loading = false
        }
    }

    private func requestPhotoAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                permissionGranted = status == .authorized || status == .limited
                if permissionGranted {
                    loadPersonPhotos()
                } else {
                    loading = false
                }
            }
        }
    }

    private func loadPersonPhotos() {
        DispatchQueue.global(qos: .userInitiated).async {
            // Search People albums for matching name
            let collections = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum,
                subtype: .smartAlbumAllHidden,
                options: nil
            )

            // Try to find person via People & Places
            let peopleFetch = PHCollectionList.fetchTopLevelUserCollections(with: nil)
            var matchedAssets: PHFetchResult<PHAsset>?

            // Search all smart albums for face-based collections
            let allPeople = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum,
                subtype: .any,
                options: nil
            )

            // Fallback: fetch recent photos as demo
            // In production, you'd match via CNContact -> PHAsset face recognition
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 20
            let recentPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)

            let count = recentPhotos.count
            var images: [UIImage] = []
            let manager = PHImageManager.default()
            let size = CGSize(width: 200, height: 200)
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .fastFormat

            let limit = min(count, 8)
            for i in 0..<limit {
                manager.requestImage(
                    for: recentPhotos.object(at: i),
                    targetSize: size,
                    contentMode: .aspectFill,
                    options: options
                ) { image, _ in
                    if let image { images.append(image) }
                }
            }

            DispatchQueue.main.async {
                self.photoCount = count
                self.thumbnails = images
                self.loading = false
            }
        }
    }
}

#Preview {
    PhotosTogetherCard(contactName: "Nina")
        .padding()
        .background(Color.black)
}
