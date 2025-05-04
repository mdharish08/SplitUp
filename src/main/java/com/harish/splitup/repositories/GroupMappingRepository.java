package com.harish.splitup.repositories;

import com.harish.splitup.entities.GroupMapping;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface GroupMappingRepository extends JpaRepository<GroupMapping,Long> {

    List<GroupMapping> findAllByMemberId(long memberId);

    List<GroupMapping> findAllByGroupId(long groupId);

    List<GroupMapping> findAllByGroupIdIn(List<Long> groupIds);
}
