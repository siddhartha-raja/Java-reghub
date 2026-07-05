package com.reghub.service;

import org.springframework.web.multipart.MultipartFile;

public interface StorageService {

    StoredFile store(MultipartFile file);

    StoredObject load(String key);

    void delete(String key);
}
