package com.reghub.service;

import com.reghub.model.Post;
import com.reghub.repository.PostRepository;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

@Service
public class PostService {

    private static final Logger log = LoggerFactory.getLogger(PostService.class);

    private final PostRepository postRepository;
    private final StorageService storageService;

    public PostService(PostRepository postRepository, StorageService storageService) {
        this.postRepository = postRepository;
        this.storageService = storageService;
    }

    @Transactional(readOnly = true)
    public List<Post> findAll() {
        return postRepository.findAllByOrderByCreatedAtDesc();
    }

    @Transactional
    public Post createPost(String title, MultipartFile image) {
        if (!StringUtils.hasText(title)) {
            throw new IllegalArgumentException("Title is required");
        }
        if (image == null || image.isEmpty()) {
            throw new IllegalArgumentException("Image is required");
        }

        StoredFile storedFile = storageService.store(image);
        Post post = new Post(title.trim(), storedFile.url(), storedFile.key());
        return postRepository.save(post);
    }

    @Transactional(readOnly = true)
    public StoredObject loadImage(Long id) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Post not found"));
        return storageService.load(post.getImageKey());
    }

    @Transactional
    public void deletePost(Long id) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Post not found"));
        postRepository.delete(post);

        try {
            storageService.delete(post.getImageKey());
        } catch (StorageException ex) {
            log.warn("Post {} was deleted from the database, but image {} could not be deleted from storage: {}",
                    id, post.getImageKey(), ex.getMessage());
        }
    }
}
