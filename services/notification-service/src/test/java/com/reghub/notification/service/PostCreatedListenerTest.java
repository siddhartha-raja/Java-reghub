package com.reghub.notification.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.reghub.notification.event.PostCreatedEvent;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;

@ExtendWith(OutputCaptureExtension.class)
class PostCreatedListenerTest {

    private final PostCreatedListener listener = new PostCreatedListener();

    @Test
    void logsPostCreatedEvent(CapturedOutput output) {
        listener.onPostCreated(new PostCreatedEvent(
                10L,
                "Demo",
                "https://example.com/demo.png",
                "posts/demo.png",
                Instant.parse("2026-07-07T15:00:00Z")
        ));

        assertThat(output).contains("Received post.created event");
        assertThat(output).contains("postId=10");
        assertThat(output).contains("title=Demo");
    }
}
