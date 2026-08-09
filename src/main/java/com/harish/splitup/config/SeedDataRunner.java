package com.harish.splitup.config;

import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.*;
import com.harish.splitup.entities.Category;
import com.harish.splitup.repositories.CategoryRepository;
import com.harish.splitup.repositories.UserRepository;
import com.harish.splitup.service.ExpenseService;
import com.harish.splitup.service.GroupService;
import com.harish.splitup.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

@Component
@RequiredArgsConstructor
public class SeedDataRunner implements CommandLineRunner {

    private final UserRepository userRepository;
    private final UserService userService;
    private final GroupService groupService;
    private final ExpenseService expenseService;
    private final CategoryRepository categoryRepository;

    @Override
    public void run(String... args) {
        // Always ensure categories exist (idempotent)
        if (categoryRepository.count() == 0) {
            Stream.of("Food & Drink", "Transportation", "Entertainment",
                            "Utilities", "Rent", "Shopping", "Other")
                    .map(name -> Category.builder().withName(name).build())
                    .forEach(categoryRepository::save);
        }

        // Guard: demo data only once
        if (userRepository.findByEmailId("alice@splitup.dev").isPresent()) {
            return;
        }

        System.out.println("\n  [Seed] Seeding demo data...");

        // ── 1. Users ─────────────────────────────────────────────────────────
        record U(String first, String last, String email, String password) {
        }

        List<U> defs = List.of(
                new U("Alice", "Johnson", "alice@splitup.dev", "Alice@123"),
                new U("Bob", "Smith", "bob@splitup.dev", "Bob@123"),
                new U("Carol", "Davis", "carol@splitup.dev", "Carol@123"),
                new U("David", "Lee", "david@splitup.dev", "David@123"),
                new U("Eva", "Martinez", "eva@splitup.dev", "Eva@123")
        );

        Long[] ids = new Long[defs.size()];
        for (int i = 0; i < defs.size(); i++) {
            U u = defs.get(i);
            SignupRequestDto req = new SignupRequestDto();
            req.setFirstName(u.first());
            req.setLastName(u.last());
            req.setEmailId(u.email());
            req.setPassword(u.password());
            ids[i] = userService.registerUser(req).getId();
        }

        Long aId = ids[0], bId = ids[1], cId = ids[2], dId = ids[3], eId = ids[4];
        String aE = defs.get(0).email(), bE = defs.get(1).email(),
                cE = defs.get(2).email(), dE = defs.get(3).email(),
                eE = defs.get(4).email();

        // ── 2. Friendships ────────────────────────────────────────────────────
        addFriend(aId, bE);
        addFriend(aId, cE);
        addFriend(aId, dE);
        addFriend(aId, eE);
        addFriend(bId, cE);
        addFriend(bId, dE);
        addFriend(cId, dE);
        addFriend(eId, bE);

        // ── 3. Groups ─────────────────────────────────────────────────────────
        Long tripId = createGroup(aId, "Summer Trip 2025", "TRIP",
                "Road trip across the coast",
                members(aId, aE, bId, bE, cId, cE, dId, dE));

        Long aptId = createGroup(aId, "Apartment 4B", "APARTMENT",
                "Shared apartment bills",
                members(aId, aE, eId, eE, bId, bE));

        Long movieId = createGroup(bId, "Movie Nights", "OTHER",
                "Weekly movie outings",
                members(bId, bE, cId, cE, dId, dE, eId, eE));

        // ── 4. Expenses ───────────────────────────────────────────────────────
        Category food = findCat("Food");
        Category travel = findCat("Transportation");
        Category util = findCat("Utilities");
        Category entmt = findCat("Entertainment");

        // Personal
        expense("Dinner at Olive Garden", food, 60.00, aId, null,
                split(aId, 60, 30), split(bId, 0, 30));
        expense("Morning coffee run", food, 16.00, bId, null,
                split(bId, 16, 8), split(aId, 0, 8));
        expense("Cinema — Dune Part Two", entmt, 45.00, cId, null,
                split(cId, 45, 15), split(aId, 0, 15), split(dId, 0, 15));

        // Summer Trip
        if (tripId != null) {
            expense("Hotel — 2 nights", travel, 240.00, aId, tripId,
                    split(aId, 240, 60), split(bId, 0, 60), split(cId, 0, 60), split(dId, 0, 60));
            expense("Fuel for road trip", travel, 80.00, bId, tripId,
                    split(bId, 80, 20), split(aId, 0, 20), split(cId, 0, 20), split(dId, 0, 20));
            expense("Supermarket haul", food, 96.00, cId, tripId,
                    split(cId, 96, 24), split(aId, 0, 24), split(bId, 0, 24), split(dId, 0, 24));
            expense("Six Flags tickets", entmt, 160.00, dId, tripId,
                    split(dId, 160, 40), split(aId, 0, 40), split(bId, 0, 40), split(cId, 0, 40));
        }

        // Apartment 4B
        if (aptId != null) {
            expense("Electricity + water", util, 90.00, eId, aptId,
                    split(eId, 90, 30), split(aId, 0, 30), split(bId, 0, 30));
            expense("Monthly internet", util, 60.00, aId, aptId,
                    split(aId, 60, 20), split(eId, 0, 20), split(bId, 0, 20));
            expense("Weekly groceries", food, 75.00, bId, aptId,
                    split(bId, 75, 25), split(aId, 0, 25), split(eId, 0, 25));
        }

        // Movie Nights
        if (movieId != null) {
            expense("Snacks for movie night", entmt, 40.00, bId, movieId,
                    split(bId, 40, 10), split(cId, 0, 10), split(dId, 0, 10), split(eId, 0, 10));
            expense("Netflix + Prime", entmt, 48.00, cId, movieId,
                    split(cId, 48, 12), split(bId, 0, 12), split(dId, 0, 12), split(eId, 0, 12));
        }

        // ── Summary ───────────────────────────────────────────────────────────
        System.out.println();
        System.out.println("╔══════════════════════════════════════════════════════════════╗");
        System.out.println("║             SEED COMPLETE — Demo Credentials                ║");
        System.out.println("╠══════════════════════════════════════════════════════════════╣");
        System.out.printf("║  %-16s %-26s %-12s %-5s ║%n", "Name", "Email", "Password", "ID");
        System.out.println("║  ──────────────── ────────────────────────── ──────────── ───── ║");
        for (int i = 0; i < defs.size(); i++) {
            U u = defs.get(i);
            String tag = i == 0 ? "★ " : "  ";
            String name = u.first() + " " + u.last();
            System.out.printf("║ %s%-16s %-26s %-12s %-5s ║%n", tag, name, u.email(), u.password(), ids[i]);
        }
        System.out.println("╠══════════════════════════════════════════════════════════════╣");
        System.out.println("║  ★ Main → alice@splitup.dev  /  Alice@123                   ║");
        System.out.println("╚══════════════════════════════════════════════════════════════╝");
        System.out.println();
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private void addFriend(Long userId, String friendEmail) {
        try {
            AddFriendRequestDto req = new AddFriendRequestDto();
            req.setEmailId(friendEmail);
            req.setCurrencyCode("USD");
            userService.addFriend(userId, req);
        } catch (Exception e) {
            System.out.printf("  [Seed] warn addFriend(%d, %s): %s%n", userId, friendEmail, e.getMessage());
        }
    }

    private Long createGroup(Long creatorId, String name, String type, String desc,
                             List<CreateGroupRequestDto.GroupMemberRequestDto> memberList) {
        try {
            CreateGroupRequestDto req = new CreateGroupRequestDto(
                    name,
                    AppConstants.GroupType.valueOf(type),
                    AppConstants.CurrencyCode.USD,
                    desc,
                    memberList
            );
            return groupService.createGroup(creatorId, req).id();
        } catch (Exception e) {
            System.out.printf("  [Seed] warn createGroup(%s): %s%n", name, e.getMessage());
            return null;
        }
    }

    private List<CreateGroupRequestDto.GroupMemberRequestDto> members(Object... pairs) {
        List<CreateGroupRequestDto.GroupMemberRequestDto> list = new ArrayList<>();
        for (int i = 0; i < pairs.length; i += 2) {
            list.add(new CreateGroupRequestDto.GroupMemberRequestDto((Long) pairs[i]));
        }
        return list;
    }

    private Category findCat(String hint) {
        return categoryRepository.findAll().stream()
                .filter(c -> c.getName().toLowerCase().contains(hint.toLowerCase()))
                .findFirst()
                .orElseGet(() -> categoryRepository.findAll().get(0));
    }

    @SafeVarargs
    private void expense(String desc, Category cat, double cost, Long payerId,
                         Long groupId, SplitDetailsDto... splits) {
        try {
            ExpenseDto dto = new ExpenseDto();
            dto.setDescription(desc);
            dto.setCategory(cat.toDTO());
            dto.setExpenseType("EXPENSE");
            dto.setCost(BigDecimal.valueOf(cost));
            dto.setCurrencyCode("USD");
            dto.setPaidBy(payerId);
            dto.setGroupId(groupId);
            dto.setUsers(List.of(splits));
            expenseService.createExpense(dto);
        } catch (Exception e) {
            System.out.printf("  [Seed] warn expense(%s): %s%n", desc, e.getMessage());
        }
    }

    private SplitDetailsDto split(Long userId, double paid, double owed) {
        SplitDetailsDto s = new SplitDetailsDto();
        s.setUserId(userId);
        s.setPaidShare(BigDecimal.valueOf(paid));
        s.setOwedShare(BigDecimal.valueOf(owed));
        return s;
    }
}
