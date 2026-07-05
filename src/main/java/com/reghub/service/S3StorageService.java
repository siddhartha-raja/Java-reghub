package com.reghub.service;

import java.io.IOException;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

@Service
public class S3StorageService implements StorageService {

    private final S3Client s3Client;
    private final String bucketName;
    private final String region;

    public S3StorageService(
            S3Client s3Client,
            @Value("${app.aws.s3.bucket}") String bucketName,
            @Value("${app.aws.region}") String region
    ) {
        this.s3Client = s3Client;
        this.bucketName = bucketName;
        this.region = region;
    }

    @Override
    public StoredFile store(MultipartFile file) {
        String contentType = file.getContentType() == null ? "application/octet-stream" : file.getContentType();
        String key = "posts/" + UUID.randomUUID() + "-" + cleanFileName(file.getOriginalFilename());

        try {
            PutObjectRequest request = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .contentType(contentType)
                    .build();

            s3Client.putObject(request, RequestBody.fromInputStream(file.getInputStream(), file.getSize()));
            return new StoredFile(key, publicUrl(key));
        } catch (IOException ex) {
            throw new StorageException("Could not read uploaded image", ex);
        } catch (RuntimeException ex) {
            throw new StorageException("Could not upload image to S3", ex);
        }
    }

    @Override
    public StoredObject load(String key) {
        try {
            GetObjectRequest request = GetObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build();
            ResponseBytes<GetObjectResponse> response = s3Client.getObjectAsBytes(request);
            String contentType = response.response().contentType() == null
                    ? "application/octet-stream"
                    : response.response().contentType();
            return new StoredObject(response.asByteArray(), contentType);
        } catch (RuntimeException ex) {
            throw new StorageException("Could not load image from S3", ex);
        }
    }

    @Override
    public void delete(String key) {
        try {
            DeleteObjectRequest request = DeleteObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build();
            s3Client.deleteObject(request);
        } catch (RuntimeException ex) {
            throw new StorageException("Could not delete image from S3", ex);
        }
    }

    private String publicUrl(String key) {
        return "https://" + bucketName + ".s3." + region + ".amazonaws.com/" + key;
    }

    private String cleanFileName(String originalFileName) {
        if (originalFileName == null || originalFileName.isBlank()) {
            return "upload";
        }
        return originalFileName.replaceAll("[^a-zA-Z0-9._-]", "_");
    }
}
