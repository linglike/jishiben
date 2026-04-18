export interface Note {
  id: string;
  title: string;
  content: string;
  /** 分类名称，空字符串表示未分类 */
  category: string;
  updatedAt: number;
}

export const FILTER_ALL = '__ALL__';
export const FILTER_UNCATEGORIZED = '__NONE__';

export function createEmptyNote(): Note {
  return {
    id: '',
    title: '',
    content: '',
    category: '',
    updatedAt: Date.now()
  };
}

export function generateNoteId(): string {
  return `${Date.now()}_${Math.random().toString(36).slice(2, 11)}`;
}

export function normalizeCategoryLabel(raw: string): string {
  const t = raw.trim();
  return t.length > 0 ? t : '未分类';
}

export function collectUniqueCategoryNames(notes: Note[]): string[] {
  const bucket: string[] = [];
  const seen = new Set<string>();
  for (let i = 0; i < notes.length; i++) {
    const c = notes[i].category.trim();
    if (c.length > 0 && !seen.has(c)) {
      seen.add(c);
      bucket.push(c);
    }
  }
  bucket.sort();
  return bucket;
}
