import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { Note } from '../model/Note';

const PREF_NAME = 'notebook_preferences';
const KEY_NOTES = 'notes_json';

function parseNotes(raw: string): Note[] {
  try {
    const parsed = JSON.parse(raw) as Object[];
    if (!Array.isArray(parsed)) {
      return [];
    }
    const out: Note[] = [];
    for (let i = 0; i < parsed.length; i++) {
      const row = parsed[i] as Record<string, Object>;
      const cat = row['category'];
      out.push({
        id: `${row['id'] ?? ''}`,
        title: `${row['title'] ?? ''}`,
        content: `${row['content'] ?? ''}`,
        category: cat !== undefined ? `${cat}` : '',
        updatedAt: Number(row['updatedAt'] ?? 0)
      });
    }
    return out.sort((a: Note, b: Note) => b.updatedAt - a.updatedAt);
  } catch (_e) {
    return [];
  }
}

export class NoteStore {
  private static instance: NoteStore = new NoteStore();
  private pref: preferences.Preferences | null = null;

  static getInstance(): NoteStore {
    return NoteStore.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    this.pref = await preferences.getPreferences(context, PREF_NAME);
  }

  async loadAll(): Promise<Note[]> {
    if (!this.pref) {
      return [];
    }
    const raw = await this.pref.get(KEY_NOTES, '[]') as string;
    return parseNotes(raw);
  }

  async saveAll(notes: Note[]): Promise<void> {
    if (!this.pref) {
      return;
    }
    await this.pref.put(KEY_NOTES, JSON.stringify(notes));
    await this.pref.flush();
  }
}
