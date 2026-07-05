package com.reghub.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.reghub.model.Post;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@DataJpaTest
@Testcontainers
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class PostRepositoryIT {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.4")
            .withDatabaseName("reghub_test")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void databaseProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
    }

    @Autowired
    private PostRepository postRepository;

    @Test
    void findsPostsNewestFirst() throws InterruptedException {
        postRepository.saveAndFlush(new Post("First", "https://example.com/first.png", "posts/first.png"));
        Thread.sleep(10);
        postRepository.save(new Post("Second", "https://example.com/second.png", "posts/second.png"));

        assertThat(postRepository.findAllByOrderByCreatedAtDesc())
                .extracting(Post::getTitle)
                .containsExactly("Second", "First");
    }
}
