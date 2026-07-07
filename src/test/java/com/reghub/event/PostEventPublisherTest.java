package com.reghub.event;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.reghub.model.Post;
import java.util.concurrent.CompletableFuture;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.kafka.core.KafkaTemplate;

class PostEventPublisherTest {

    private final KafkaTemplate<String, Object> kafkaTemplate = org.mockito.Mockito.mock(KafkaTemplate.class);
    private final PostEventPublisher publisher = new PostEventPublisher(
            kafkaTemplate,
            "post.created",
            "post.deleted"
    );

    @Test
    void publishPostCreatedSendsJsonSerializableEvent() {
        Post post = new Post("Demo", "https://example.com/demo.png", "posts/demo.png");
        when(kafkaTemplate.send(eq("post.created"), eq(null), org.mockito.ArgumentMatchers.any()))
                .thenReturn(CompletableFuture.completedFuture(null));

        publisher.publishPostCreated(post);

        ArgumentCaptor<Object> eventCaptor = ArgumentCaptor.forClass(Object.class);
        verify(kafkaTemplate).send(eq("post.created"), eq(null), eventCaptor.capture());
        PostCreatedEvent event = (PostCreatedEvent) eventCaptor.getValue();
        assertThat(event.title()).isEqualTo("Demo");
        assertThat(event.imageUrl()).isEqualTo("https://example.com/demo.png");
        assertThat(event.imageKey()).isEqualTo("posts/demo.png");
        assertThat(event.occurredAt()).isNotNull();
    }

    @Test
    void publishPostDeletedSendsJsonSerializableEvent() {
        Post post = new Post("Demo", "https://example.com/demo.png", "posts/demo.png");
        when(kafkaTemplate.send(eq("post.deleted"), eq(null), org.mockito.ArgumentMatchers.any()))
                .thenReturn(CompletableFuture.completedFuture(null));

        publisher.publishPostDeleted(post);

        ArgumentCaptor<Object> eventCaptor = ArgumentCaptor.forClass(Object.class);
        verify(kafkaTemplate).send(eq("post.deleted"), eq(null), eventCaptor.capture());
        PostDeletedEvent event = (PostDeletedEvent) eventCaptor.getValue();
        assertThat(event.title()).isEqualTo("Demo");
        assertThat(event.imageKey()).isEqualTo("posts/demo.png");
        assertThat(event.occurredAt()).isNotNull();
    }
}
