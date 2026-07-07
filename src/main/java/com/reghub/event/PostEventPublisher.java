package com.reghub.event;

import com.reghub.model.Post;
import java.time.Instant;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@Component
public class PostEventPublisher {

    private static final Logger log = LoggerFactory.getLogger(PostEventPublisher.class);

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final String postCreatedTopic;
    private final String postDeletedTopic;

    public PostEventPublisher(
            KafkaTemplate<String, Object> kafkaTemplate,
            @Value("${app.kafka.topic.post-created}") String postCreatedTopic,
            @Value("${app.kafka.topic.post-deleted}") String postDeletedTopic
    ) {
        this.kafkaTemplate = kafkaTemplate;
        this.postCreatedTopic = postCreatedTopic;
        this.postDeletedTopic = postDeletedTopic;
    }

    public void publishPostCreated(Post post) {
        PostCreatedEvent event = new PostCreatedEvent(
                post.getId(),
                post.getTitle(),
                post.getImageUrl(),
                post.getImageKey(),
                Instant.now()
        );
        send(postCreatedTopic, post.getId(), event);
    }

    public void publishPostDeleted(Post post) {
        PostDeletedEvent event = new PostDeletedEvent(
                post.getId(),
                post.getTitle(),
                post.getImageKey(),
                Instant.now()
        );
        send(postDeletedTopic, post.getId(), event);
    }

    private void send(String topic, Long postId, Object event) {
        String key = postId == null ? null : postId.toString();
        try {
            kafkaTemplate.send(topic, key, event)
                    .whenComplete((result, ex) -> {
                        if (ex != null) {
                            log.warn("Failed to publish Kafka event to topic {} for post {}: {}",
                                    topic, postId, ex.getMessage());
                        }
                    });
        } catch (RuntimeException ex) {
            log.warn("Failed to start Kafka publish to topic {} for post {}: {}", topic, postId, ex.getMessage());
        }
    }
}
