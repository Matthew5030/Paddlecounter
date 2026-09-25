import SwiftUI

struct HistoryScreen: View {
    let sessions: [SessionRecord]

    private var totalHits: Int { sessions.reduce(0) { $0 + $1.totalHits } }
    private var totalRallies: Int { sessions.reduce(0) { $0 + $1.rallies.count } }
    private var personalBest: Int { sessions.map(\.best).max() ?? 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                PCBackground(accent: PCTheme.aqua)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 18) {
                        header

                        if sessions.isEmpty {
                            emptyState
                        } else {
                            overview

                            HStack {
                                Text("SESSIONS")
                                    .font(.caption.bold())
                                    .tracking(1.4)
                                    .foregroundStyle(PCTheme.textSecondary)
                                Spacer()
                                Text("\(sessions.count) total")
                                    .font(.caption)
                                    .foregroundStyle(PCTheme.textSecondary)
                            }
                            .padding(.top, 6)

                            ForEach(sessions) { session in
                                NavigationLink {
                                    SessionDetailScreen(session: session)
                                } label: {
                                    SessionCard(session: session)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: PCTheme.contentWidth)
                    .padding(.horizontal, PCTheme.pageInset)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        PCPageHeader(
            eyebrow: "Your play",
            title: "History",
            accent: PCTheme.aqua,
            systemImage: "chart.line.uptrend.xyaxis"
        )
    }

    private var overview: some View {
        HStack {
            PCMetric(value: "\(totalHits)", label: "Total hits")
            Spacer()
            PCMetric(value: "\(totalRallies)", label: "Rallies", alignment: .center)
            Spacer()
            PCMetric(value: "\(personalBest)", label: "Personal best", alignment: .trailing)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [PCTheme.aqua.opacity(0.18), Color.white.opacity(0.055)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(PCTheme.border))
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(PCTheme.aqua.opacity(0.13))
                    .frame(width: 112, height: 112)
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 43))
                    .foregroundStyle(PCTheme.aqua)
            }
            Text("Your rallies will live here")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Finish your first session to see every rally, your best run and confidence history.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(PCTheme.textSecondary)
                .frame(maxWidth: 290)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .padding(.horizontal, 24)
        .pcCard()
    }
}

private struct SessionCard: View {
    let session: SessionRecord

    private var sortedRallies: [RallyRecord] {
        session.rallies.sorted { $0.startedAt < $1.startedAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.startedAt.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(session.startedAt.formatted(date: .omitted, time: .shortened) + durationText)
                        .font(.caption)
                        .foregroundStyle(PCTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(PCTheme.textSecondary)
                    .padding(.top, 6)
            }

            HStack(spacing: 0) {
                PCMetric(value: "\(session.totalHits)", label: "hits")
                    .frame(maxWidth: .infinity, alignment: .leading)
                PCMetric(value: "\(session.rallies.count)", label: "rallies", alignment: .center)
                    .frame(maxWidth: .infinity)
                PCMetric(value: "\(session.best)", label: "best", alignment: .trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            if !sortedRallies.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(sortedRallies.enumerated()), id: \.element.id) { index, rally in
                            VStack(spacing: 2) {
                                Text("\(rally.hits)")
                                    .font(.subheadline.bold().monospacedDigit())
                                    .foregroundStyle(rally.hits == session.best ? PCTheme.lime : .white)
                                Text("R\(index + 1)")
                                    .font(.caption2)
                                    .foregroundStyle(PCTheme.textSecondary)
                            }
                            .frame(minWidth: 44)
                            .padding(.vertical, 9)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
        .padding(20)
        .pcCard()
    }

    private var durationText: String {
        guard let endedAt = session.endedAt else { return "" }
        let duration = endedAt.timeIntervalSince(session.startedAt)
        guard duration >= 60 else { return " · under a minute" }
        return " · \(Int(duration / 60)) min"
    }
}

private struct SessionDetailScreen: View {
    let session: SessionRecord

    private var rallies: [RallyRecord] {
        session.rallies.sorted { $0.startedAt < $1.startedAt }
    }

    var body: some View {
        ZStack {
            PCBackground(accent: PCTheme.aqua)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HStack {
                        PCMetric(value: "\(session.totalHits)", label: "Total hits")
                        Spacer()
                        PCMetric(value: "\(session.best)", label: "Best rally", alignment: .center)
                        Spacer()
                        PCMetric(
                            value: session.averageRally.formatted(.number.precision(.fractionLength(1))),
                            label: "Average",
                            alignment: .trailing
                        )
                    }
                    .padding(20)
                    .pcCard()

                    ForEach(Array(rallies.enumerated()), id: \.element.id) { index, rally in
                        HStack(spacing: 15) {
                            Text("\(index + 1)")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(PCTheme.ink)
                                .frame(width: 34, height: 34)
                                .background(rally.hits == session.best ? PCTheme.lime : PCTheme.aqua, in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(rally.hits) hits")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text(rally.startedAt.formatted(date: .omitted, time: .standard))
                                    .font(.caption)
                                    .foregroundStyle(PCTheme.textSecondary)
                            }
                            Spacer()
                            if rally.averageConfidence > 0 {
                                Text(rally.averageConfidence, format: .percent.precision(.fractionLength(0)))
                                    .font(.subheadline.bold().monospacedDigit())
                                    .foregroundStyle(PCTheme.textSecondary)
                            }
                        }
                        .padding(16)
                        .pcCard()
                    }
                }
                .frame(maxWidth: PCTheme.contentWidth)
                .padding(.horizontal, PCTheme.pageInset)
                .padding(.top, 18)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(session.startedAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PCTheme.ink.opacity(0.95), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
