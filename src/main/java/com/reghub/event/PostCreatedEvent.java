package com.reghub.event;

import java.time.Instant;

public record PostCreatedEvent(
        Long postId,
        String title,
        String imageUrl,
        String imageKey,
        Instant occurredAt
) {
}
