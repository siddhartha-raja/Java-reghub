package com.reghub.controller;

import com.reghub.service.PostService;
import com.reghub.service.StoredObject;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

@Controller
@Validated
public class PostController {

    private final PostService postService;

    public PostController(PostService postService) {
        this.postService = postService;
    }

    @GetMapping("/")
    public String index(Model model) {
        model.addAttribute("posts", postService.findAll());
        return "posts";
    }

    @PostMapping("/posts")
    public String createPost(
            @RequestParam @NotBlank String title,
            @RequestParam("image") MultipartFile image
    ) {
        postService.createPost(title, image);
        return "redirect:/?created=true";
    }

    @GetMapping("/posts/{id}/image")
    public ResponseEntity<byte[]> image(@PathVariable Long id) {
        StoredObject image = postService.loadImage(id);
        return ResponseEntity.ok()
                .header(HttpHeaders.CACHE_CONTROL, "public, max-age=300")
                .contentType(MediaType.parseMediaType(image.contentType()))
                .body(image.content());
    }

    @PostMapping("/posts/{id}/delete")
    public String deletePost(@PathVariable Long id) {
        postService.deletePost(id);
        return "redirect:/?deleted=true";
    }
}
