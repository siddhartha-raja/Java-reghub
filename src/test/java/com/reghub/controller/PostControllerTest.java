package com.reghub.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import com.reghub.service.PostService;
import com.reghub.service.StoredObject;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(PostController.class)
class PostControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private PostService postService;

    @Test
    void indexShowsPostsPage() throws Exception {
        when(postService.findAll()).thenReturn(List.of());

        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(view().name("posts"))
                .andExpect(model().attributeExists("posts"));
    }

    @Test
    void createPostRedirectsToHome() throws Exception {
        MockMultipartFile image = new MockMultipartFile(
                "image",
                "demo.png",
                "image/png",
                "fake-image".getBytes()
        );

        mockMvc.perform(multipart("/posts")
                        .file(image)
                        .param("title", "Demo post"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/?created=true"));

        verify(postService).createPost(eq("Demo post"), any(MultipartFile.class));
    }

    @Test
    void imageStreamsPostImage() throws Exception {
        when(postService.loadImage(10L)).thenReturn(new StoredObject("image".getBytes(), "image/png"));

        mockMvc.perform(get("/posts/10/image"))
                .andExpect(status().isOk())
                .andExpect(content().contentType("image/png"))
                .andExpect(content().bytes("image".getBytes()));
    }

    @Test
    void deletePostRedirectsToHome() throws Exception {
        mockMvc.perform(post("/posts/10/delete"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/?deleted=true"));

        verify(postService).deletePost(10L);
    }
}
