// Reads today's KOrganizer/Akonadi calendar items across all calendar
// collections (local and synced, e.g. Google) and prints the ones tagged
// with a categories() entry of "f", "s" or "b" as a JSON array of
// {"start": ISO8601, "end": ISO8601, "mode": "f"|"s"|"b"} to stdout.
// Recurring incidences are expanded to today's occurrence(s) only.

#include <QCoreApplication>
#include <QDate>
#include <QDateTime>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTimeZone>
#include <iostream>

#include <Akonadi/CollectionFetchJob>
#include <Akonadi/Item>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>

#include <KCalendarCore/Event>
#include <KCalendarCore/Recurrence>
#include <KCalendarCore/Todo>

namespace
{
QString modeFromCategories(const QStringList &categories)
{
    for (const QString &category : categories) {
        const QString trimmed = category.trimmed().toLower();
        if (trimmed == QLatin1String("f") || trimmed == QLatin1String("s") || trimmed == QLatin1String("b")) {
            return trimmed;
        }
    }
    return QString();
}
}

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);

    const QDateTime todayStart(QDate::currentDate(), QTime(0, 0), QTimeZone::systemTimeZone());
    const QDateTime todayEnd = todayStart.addDays(1);

    Akonadi::CollectionFetchJob collectionJob(Akonadi::Collection::root(), Akonadi::CollectionFetchJob::Recursive);
    collectionJob.setAutoDelete(false);
    if (!collectionJob.exec()) {
        std::cerr << "Failed to fetch Akonadi collections: " << collectionJob.errorString().toStdString() << std::endl;
        return 1;
    }

    QJsonArray results;

    const auto collections = collectionJob.collections();
    for (const Akonadi::Collection &collection : collections) {
        if (!collection.contentMimeTypes().contains(QLatin1String("text/calendar"))) {
            continue;
        }

        Akonadi::ItemFetchJob itemJob(collection);
        itemJob.setAutoDelete(false);
        itemJob.fetchScope().fetchFullPayload(true);
        if (!itemJob.exec()) {
            continue;
        }

        const auto items = itemJob.items();
        for (const Akonadi::Item &item : items) {
            KCalendarCore::Incidence::Ptr incidence;
            if (item.hasPayload<KCalendarCore::Event::Ptr>()) {
                incidence = item.payload<KCalendarCore::Event::Ptr>();
            } else if (item.hasPayload<KCalendarCore::Todo::Ptr>()) {
                incidence = item.payload<KCalendarCore::Todo::Ptr>();
            } else {
                continue;
            }

            const QString mode = modeFromCategories(incidence->categories());
            if (mode.isEmpty()) {
                continue;
            }

            QDateTime start = incidence->dtStart();
            QDateTime end;
            if (const auto event = incidence.dynamicCast<KCalendarCore::Event>()) {
                end = event->dtEnd().isValid() ? event->dtEnd() : start.addSecs(3600);
            } else if (const auto todo = incidence.dynamicCast<KCalendarCore::Todo>()) {
                if (!start.isValid()) {
                    start = todo->dtDue();
                }
                end = todo->dtDue().isValid() ? todo->dtDue() : start.addSecs(3600);
            }

            if (!start.isValid() || !end.isValid()) {
                continue;
            }

            QList<QPair<QDateTime, QDateTime>> occurrences;
            if (incidence->recurs()) {
                const qint64 durationSecs = start.secsTo(end);
                const auto occurrenceStarts = incidence->recurrence()->timesInInterval(todayStart, todayEnd);
                for (const QDateTime &occStart : occurrenceStarts) {
                    occurrences.append({occStart, occStart.addSecs(durationSecs)});
                }
            } else if (start < todayEnd && end > todayStart) {
                occurrences.append({start, end});
            }

            for (const auto &occurrence : occurrences) {
                QJsonObject obj;
                obj[QStringLiteral("start")] = occurrence.first.toString(Qt::ISODate);
                obj[QStringLiteral("end")] = occurrence.second.toString(Qt::ISODate);
                obj[QStringLiteral("mode")] = mode;
                obj[QStringLiteral("summary")] = incidence->summary();
                results.append(obj);
            }
        }
    }

    std::cout << QJsonDocument(results).toJson(QJsonDocument::Compact).toStdString() << std::endl;
    return 0;
}
