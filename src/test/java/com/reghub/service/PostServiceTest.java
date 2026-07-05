package com.reghub.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.reghub.model.Post;
import com.reghub.repository.PostRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

@ExtendWith(MockitoExtension.class)
class PostServiceTest {

    @Mock
    private PostRepository postRepository;

    @Mock
    private StorageService storageService;

    @InjectMocks
    private PostService postService;

    @Test
    void createPostStoresFileAndSavesPost() {
        MockMultipartFile image = new MockMultipartFile("image", "demo.png", "image/png", "data".getBytes());
        when(storageService.store(image)).thenReturn(new StoredFile("posts/demo.png", "https://example.com/demo.png"));
        when(postRepository.save(any(Post.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Post saved = postService.createPost("  Demo title  ", image);

        ArgumentCaptor<Post> postCaptor = ArgumentCaptor.forClass(Post.class);
        verify(postRepository).save(postCaptor.capture());
        assertThat(postCaptor.getValue().getTitle()).isEqualTo("Demo title");
        assertThat(saved.getImageUrl()).isEqualTo("https://example.com/demo.png");
    }

    @Test
    void createPostRejectsEmptyImage() {
        MockMultipartFile image = new MockMultipartFile("image", "demo.png", "image/png", new byte[0]);

        assertThatThrownBy(() -> postService.createPost("Demo", image))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Image is required");
    }

    @Test
    void loadImageUsesStoredImageKey() {
        Post post = new Post("Demo", "https://example.com/demo.png", "posts/demo.png");
        when(postRepository.findById(10L)).thenReturn(Optional.of(post));
        when(storageService.load("posts/demo.png")).thenReturn(new StoredObject("image".getBytes(), "image/png"));

        StoredObject image = postService.loadImage(10L);

        assertThat(image.contentType()).isEqualTo("image/png");
        assertThat(image.content()).isEqualTo("image".getBytes());
    }

    @Test
    void deletePostDeletesDatabaseRowAndStoredFile() {
        Post post = new Post("Demo", "https://example.com/demo.png", "posts/demo.png");
        when(postRepository.findById(10L)).thenReturn(Optional.of(post));

        postService.deletePost(10L);

        verify(postRepository).delete(post);
        verify(storageService).delete("posts/demo.png");
    }

    @Test
    void deletePostStillDeletesDatabaseRowWhenStorageDeleteFails() {
        Post post = new Post("Demo", "https://example.com/demo.png", "posts/demo.png");
        when(postRepository.findById(10L)).thenReturn(Optional.of(post));
        doThrow(new StorageException("failed", new RuntimeException())).when(storageService).delete("posts/demo.png");

        postService.deletePost(10L);

        verify(postRepository).delete(post);
    }
}
