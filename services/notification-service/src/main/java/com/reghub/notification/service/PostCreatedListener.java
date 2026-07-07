package com.reghub.notification.service;

import com.reghub.notification.event.PostCreatedEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class PostCreatedListener {

    private static final Logger log = LoggerFactory.getLogger(PostCreatedListener.class);

    @KafkaListener(
            topics = "${app.kafka.topic.post-created}",
            groupId = "${spring.kafka.consumer.group-id}"
    )
    public void onPostCreated(PostCreatedEvent event) {
        log.info("Received post.created event: postId={}, title={}, imageKey={}",
                event.postId(), event.title(), event.imageKey());
    }
}
