package com.reghub.event;

import java.time.Instant;

public record PostDeletedEvent(
        Long postId,
        String title,
        String imageKey,
        Instant occurredAt
) {
}
