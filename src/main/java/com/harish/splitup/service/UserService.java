package com.harish.splitup.service;

import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.AddFriendRequestDto;
import com.harish.splitup.dto.FriendsDto;
import com.harish.splitup.dto.GroupMetaResponseDto;
import com.harish.splitup.dto.SignupRequestDto;
import com.harish.splitup.dto.UserDto;
import com.harish.splitup.entities.*;
import com.harish.splitup.repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserService {

    private final FriendsRepository friendsRepository;
    private final BalanceRepository balanceRepository;
    private final UserRepository userRepository;
    private final GroupMappingRepository groupMappingRepository;
    private final GroupRepository groupRepository;
    private final PasswordEncoder passwordEncoder;
    private final PendingFriendInviteRepository pendingInviteRepository;

    @Transactional
    public UserDto registerUser(SignupRequestDto req) {
        String normalizedEmail = normalizeEmail(req.getEmailId());
        SplitUser existing = userRepository.findByEmailId(normalizedEmail).orElse(null);
        Timestamp now = new Timestamp(System.currentTimeMillis());

        SplitUser user;
        if (existing != null && existing.getAccountStatus() != AppConstants.AccountStatus.INVITED) {
            throw new IllegalStateException("Email already registered: " + normalizedEmail);
        } else if (existing != null) {
            existing.setFirstName(req.getFirstName());
            existing.setLastName(req.getLastName());
            existing.setEmailId(normalizedEmail);
            existing.setUserPassWord(passwordEncoder.encode(req.getPassword()));
            existing.setAccountStatus(AppConstants.AccountStatus.ACTIVE);
            existing.setUpdatedAt(now);
            user = userRepository.save(existing);
        } else {
            user = SplitUser.builder()
                    .withFirstName(req.getFirstName())
                    .withLastName(req.getLastName())
                    .withEmailId(normalizedEmail)
                    .withUserPassWord(passwordEncoder.encode(req.getPassword()))
                    .withAccountStatus(AppConstants.AccountStatus.ACTIVE)
                    .withCreatedAt(now)
                    .withUpdatedAt(now)
                    .build();
            user = userRepository.save(user);
        }

        // Convert any pending invites that were sent to this email into real friendships
        List<PendingFriendInvite> pendingInvites =
                pendingInviteRepository.findAllByInviteeEmail(normalizedEmail);

        if (!pendingInvites.isEmpty()) {
            List<Friends> newFriendships = new ArrayList<>();
            List<Balance> newBalances = new ArrayList<>();
            Set<Long> inviterIds = new java.util.HashSet<>();

            for (PendingFriendInvite invite : pendingInvites) {
                SplitUser inviter = invite.getInviter();
                if (inviter == null || inviter.getId() == null || inviterIds.contains(inviter.getId())) {
                    continue;
                }
                inviterIds.add(inviter.getId());

                if (friendsRepository.findExisting(inviter.getId(), user.getId()).isPresent()) {
                    continue;
                }

                Friends friendship = Friends.builder()
                        .withUser(inviter)
                        .withFriend(user)
                        .withCreatedAt(now)
                        .withUpdatedAt(now)
                        .withTrashed(false)
                        .build();
                newFriendships.add(friendship);

                AppConstants.CurrencyCode currency =
                        invite.getCurrencyCode() != null ? invite.getCurrencyCode() : AppConstants.CurrencyCode.USD;

                newBalances.add(Balance.builder()
                        .withUser(inviter)
                        .withFriend(user)
                        .withAmount(BigDecimal.ZERO)
                        .withCurrencyCode(currency)
                        .build());
                newBalances.add(Balance.builder()
                        .withUser(user)
                        .withFriend(inviter)
                        .withAmount(BigDecimal.ZERO)
                        .withCurrencyCode(currency)
                        .build());
            }

            friendsRepository.saveAll(newFriendships);
            balanceRepository.saveAll(newBalances);
            pendingInviteRepository.deleteAll(pendingInvites);
        }

        return user.toDTO();
    }

    @Transactional(readOnly = true)
    public List<GroupMetaResponseDto> getUserGroupMeta(long userId) {
        List<GroupMetaResponseDto> result = new ArrayList<>();
        List<Long> userGroupIds = groupMappingRepository.findAllByMemberId(userId)
                .stream().map(gm -> gm.getGroup().getGroupId()).toList();
        List<Group> userGroups = groupRepository.findAllById(userGroupIds);

        for (Group group : userGroups) {
            List<GroupMapping> groupMembers = groupMappingRepository.findAllByGroupGroupId(group.getGroupId());
            List<Long> allMemberIds = groupMembers.stream().map(gm -> gm.getMember().getId()).toList();
            List<SplitUser> membersMeta = userRepository.findAllById(allMemberIds);

            Map<Long, Balance> balanceByFriendId = new HashMap<>();
            balanceRepository.findAllByUserIdAndGroupGroupId(userId, group.getGroupId())
                    .forEach(b -> balanceByFriendId.put(b.getFriend().getId(), b));

            List<GroupMetaResponseDto.GroupMemberResponseDto> membersBalance = membersMeta.stream()
                    .map(member -> toGroupMemberMeta(member, balanceByFriendId.get(member.getId())))
                    .toList();

            result.add(new GroupMetaResponseDto(
                    group.getGroupId(),
                    group.getGroupName(),
                    group.getGroupType(),
                    group.getCurrencyCode(),
                    group.getGroupDescription(),
                    group.getCreatedAt(),
                    group.getUpdatedAt(),
                    membersBalance
            ));
        }
        return result;
    }

    @Transactional(readOnly = true)
    public List<FriendsDto> getFriendsMeta(long userId) {
        List<FriendsDto> result = new ArrayList<>();
        List<Friends> friendsList = friendsRepository.findAllByUserId(userId);
        List<Balance> userBalance = balanceRepository.findAllByUserId(userId);

        Map<Long, Balance> friendVsBalance = new HashMap<>();
        Map<Long, List<Balance>> friendVsGroupBalance = new HashMap<>();
        for (Balance balance : userBalance) {
            if (balance.getGroup() == null) {
                friendVsBalance.put(balance.getFriend().getId(), balance);
            } else {
                friendVsGroupBalance.computeIfAbsent(balance.getFriend().getId(), k -> new ArrayList<>()).add(balance);
            }
        }

        for (Friends friend : friendsList) {
            SplitUser friendMeta = friend.getUser().getId().equals(userId)
                    ? friend.getFriend()
                    : friend.getUser();

            if (friendMeta == null) continue;

            FriendsDto dto = toFriendsDto(friendMeta);

            Balance personalBalance = friendVsBalance.get(friendMeta.getId());
            if (personalBalance != null) {
                dto.setBalanceDto(personalBalance.balanceDto());
            }

            List<Balance> groupBalanceList = friendVsGroupBalance.getOrDefault(friendMeta.getId(), List.of());
            dto.setGroups(groupBalanceList.stream().map(this::toFriendsGroupDto).toList());
            result.add(dto);
        }

        // Append pending (not-yet-registered) invites sent by this user
        List<PendingFriendInvite> pendingInvites = pendingInviteRepository.findAllByInviterId(userId);
        for (PendingFriendInvite invite : pendingInvites) {
            FriendsDto dto = new FriendsDto();
            // id is intentionally null — the invitee has no account yet
            dto.setEmailId(invite.getInviteeEmail());
            dto.setFirstName(invite.getInviteeEmail()); // display email as name until they sign up
            dto.setRegistrationStatus("pending");
            dto.setGroups(new ArrayList<>());
            result.add(dto);
        }

        return result;
    }

    @Transactional
    public FriendsDto addFriend(long userId, AddFriendRequestDto req) {
        String inviteeEmail = normalizeEmail(req.getEmailId());

        SplitUser currentUser = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));

        if (inviteeEmail.equals(normalizeEmail(currentUser.getEmailId()))) {
            throw new IllegalArgumentException("You cannot add yourself as a friend");
        }

        AppConstants.CurrencyCode currencyCode = req.getCurrencyCode() != null
                ? AppConstants.CurrencyCode.valueOf(req.getCurrencyCode().trim().toUpperCase(Locale.ROOT))
                : AppConstants.CurrencyCode.USD;

        SplitUser friendUser = userRepository.findByEmailId(inviteeEmail).orElse(null);

        if (friendUser == null) {
            // Invitee not registered yet — create an invited account so they can be used in splits immediately.
            Timestamp now = new Timestamp(System.currentTimeMillis());
            friendUser = SplitUser.builder()
                    .withEmailId(inviteeEmail)
                    .withFirstName(inviteeEmail)
                    .withUserPassWord(passwordEncoder.encode(UUID.randomUUID().toString()))
                    .withAccountStatus(AppConstants.AccountStatus.INVITED)
                    .withCreatedAt(now)
                    .withUpdatedAt(now)
                    .build();
            friendUser = userRepository.save(friendUser);
        }

        if (friendsRepository.findExisting(userId, friendUser.getId()).isPresent()) {
            throw new IllegalStateException("You are already friends with this user");
        }

        Timestamp now = new Timestamp(System.currentTimeMillis());
        Friends friendship = Friends.builder()
                .withUser(currentUser)
                .withFriend(friendUser)
                .withCreatedAt(now)
                .withUpdatedAt(now)
                .withTrashed(false)
                .build();
        friendsRepository.save(friendship);

        Balance userToFriend = Balance.builder()
                .withUser(currentUser)
                .withFriend(friendUser)
                .withAmount(BigDecimal.ZERO)
                .withCurrencyCode(currencyCode)
                .build();
        Balance friendToUser = Balance.builder()
                .withUser(friendUser)
                .withFriend(currentUser)
                .withAmount(BigDecimal.ZERO)
                .withCurrencyCode(currencyCode)
                .build();
        balanceRepository.saveAll(List.of(userToFriend, friendToUser));

        FriendsDto dto = new FriendsDto();
        dto.setId(friendUser.getId());
        dto.setFirstName(friendUser.getFirstName());
        dto.setLastName(friendUser.getLastName());
        dto.setUserName(friendUser.getUsername());
        dto.setEmailId(friendUser.getEmailId());
        dto.setRegistrationStatus(resolveRegistrationStatus(friendUser));
        dto.setBalanceDto(userToFriend.balanceDto());
        dto.setGroups(new ArrayList<>());
        return dto;
    }

    private GroupMetaResponseDto.GroupMemberResponseDto toGroupMemberMeta(SplitUser member, Balance balance) {
        return new GroupMetaResponseDto.GroupMemberResponseDto(
                member.getId(),
                member.getEmailId(),
                member.getFirstName(),
                member.getLastName(),
                resolveRegistrationStatus(member),
                balance != null ? balance.balanceDto() : null
        );
    }

    private FriendsDto toFriendsDto(SplitUser friendMeta) {
        FriendsDto dto = new FriendsDto();
        dto.setId(friendMeta.getId());
        dto.setFirstName(friendMeta.getFirstName());
        dto.setLastName(friendMeta.getLastName());
        dto.setUserName(friendMeta.getUsername());
        dto.setEmailId(friendMeta.getEmailId());
        dto.setRegistrationStatus(resolveRegistrationStatus(friendMeta));
        return dto;
    }

    private FriendsDto.FriendsGroupDto toFriendsGroupDto(Balance groupBalance) {
        FriendsDto.FriendsGroupDto groupDto = new FriendsDto.FriendsGroupDto();
        groupDto.setBalanceDto(groupBalance.balanceDto());
        groupDto.setGroupId(groupBalance.getGroup().getGroupId());
        return groupDto;
    }

    private String normalizeEmail(String email) {
        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("Email is required");
        }
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private String resolveRegistrationStatus(SplitUser user) {
        if (user.getAccountStatus() == AppConstants.AccountStatus.INVITED) {
            return "pending";
        }
        return user.isEmailVerified() ? "verified" : "not_verified";
    }
}
